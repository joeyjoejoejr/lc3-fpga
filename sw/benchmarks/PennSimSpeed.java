import java.io.File;
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import javax.swing.SwingUtilities;

// Compile against tools/PennSim.jar; this class intentionally uses PennSim's
// default-package API so image loading is excluded from the timed interval.
public final class PennSimSpeed {
    private static final int EXPECTED_INSTRUCTIONS = 2_003_001;
    private static final int STOP_PC = 0x3006;
    private static final int RUNS = 6; // First run warms up the JVM.

    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 2
                || (args.length == 2 && !args[1].equals("--gui"))) {
            throw new IllegalArgumentException("usage: PennSimSpeed FILE.obj [--gui]");
        }

        boolean guiMode = args.length == 2;
        File object = new File(args[0]);
        Machine machine = new Machine();
        GUI gui = null;
        AtomicReference<CountDownLatch> stopped = new AtomicReference<>();

        if (guiMode) {
            CommandLine commands = new CommandLine(machine);
            GUI.initLookAndFeel();
            gui = new GUI(machine, commands);
            machine.setGUI(gui);
            GUI visibleGui = gui;
            SwingUtilities.invokeAndWait(visibleGui::setUpGUI);
            machine.setStoppedListener(event -> stopped.get().countDown());
        }

        long[] elapsed = new long[RUNS - 1];

        try {
            for (int run = 0; run < RUNS; run++) {
                Machine current = guiMode ? machine : new Machine();
                Runnable prepare = () -> {
                    if (guiMode) {
                        current.reset();
                    }
                    current.loadObjectFile(object);
                    current.getRegisterFile().setPC(0x3000);
                    current.getMemory().setBreakPoint(STOP_PC);
                };
                if (guiMode) {
                    SwingUtilities.invokeAndWait(prepare);
                } else {
                    prepare.run();
                }

                CountDownLatch latch = new CountDownLatch(1);
                stopped.set(latch);
                long start = System.nanoTime();
                if (guiMode) {
                    SwingUtilities.invokeLater(() -> {
                        try {
                            current.executeMany();
                        } catch (ExceptionException error) {
                            error.printStackTrace();
                            latch.countDown();
                        }
                    });
                    if (!latch.await(30, TimeUnit.SECONDS)) {
                        throw new IllegalStateException("PennSim GUI run timed out");
                    }
                } else {
                    current.executePumpedContinues(Integer.MAX_VALUE);
                }
                long nanos = System.nanoTime() - start;

                if (current.getRegisterFile().getPC() != STOP_PC
                        || current.INSTRUCTION_COUNT != EXPECTED_INSTRUCTIONS) {
                    throw new AssertionError("unexpected final PC or instruction count: "
                            + Integer.toHexString(current.getRegisterFile().getPC()) + ", "
                            + current.INSTRUCTION_COUNT);
                }

                if (run > 0) {
                    elapsed[run - 1] = nanos;
                    System.out.printf("PennSim%s run %d: %.3f s, %.0f instructions/s%n",
                            guiMode ? " GUI" : "", run,
                            nanos / 1e9, EXPECTED_INSTRUCTIONS * 1e9 / nanos);
                }
            }
        } finally {
            if (gui != null) {
                GUI visibleGui = gui;
                SwingUtilities.invokeAndWait(() -> visibleGui.getFrame().dispose());
            }
        }

        Arrays.sort(elapsed);
        long median = elapsed[elapsed.length / 2];
        System.out.printf("PennSim%s median: %.3f s, %.0f instructions/s%n",
                guiMode ? " GUI" : "",
                median / 1e9, EXPECTED_INSTRUCTIONS * 1e9 / median);
    }
}
