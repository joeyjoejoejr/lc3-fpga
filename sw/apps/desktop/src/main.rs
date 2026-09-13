use eframe::egui;
use lc3_desktop::{LoadedProgram, SourceRow, open_program_paths, source_rows};

const HISTORY_ITEMS: &[HistoryItem] = &[
    HistoryItem::new("Step 15", "x3007", "ADD R1, R1, #1", "R1 <- x0003"),
    HistoryItem::new("Step 14", "x3004", "LDR R1, R0, #0", "R1 <- x0002"),
    HistoryItem::new("Step 13", "x3003", "ADD R0, R0, #1", "R0 <- x3001"),
    HistoryItem::new("Step 12", "x3001", "AND R1, R1, #0", "R1 <- x0000"),
    HistoryItem::new("Step 11", "x2FFF", "LD R0, PTR", "R0 <- x3000"),
    HistoryItem::new("Step 10", "x2FFE", "LD R1, ZERO", "R1 <- x0000"),
    HistoryItem::new("Step 9", "x2FFD", "LEA R2, LOOP", "R2 <- x3002"),
    HistoryItem::new("Step 8", "x2FFC", "BR START", "PC <- x3000"),
];

const REGISTERS: &[RegisterRow] = &[
    RegisterRow::new("R0", "x3005", None),
    RegisterRow::new("R1", "x0003", Some("x0002")),
    RegisterRow::new("R2", "x3002", None),
    RegisterRow::new("R3", "x0000", None),
    RegisterRow::new("R4", "x0000", None),
    RegisterRow::new("R5", "x0000", None),
    RegisterRow::new("R6", "x0000", None),
    RegisterRow::new("R7", "x0000", None),
    RegisterRow::new("PC", "x3008", Some("x3007")),
    RegisterRow::new("IR", "x1261", Some("x6860")),
];

const SYMBOLS: &[(&str, &str)] = &[
    ("COUNT", "x0005"),
    ("LIMIT", "x000A"),
    ("PTR", "x300B"),
    ("ZERO", "x0000"),
];

struct Lc3DesktopApp {
    speed: ExecutionSpeed,
    bottom_panel: BottomPanel,
    loaded_program: LoadedProgram,
    load_error: Option<String>,
}

impl Default for Lc3DesktopApp {
    fn default() -> Self {
        Self {
            speed: ExecutionSpeed::StepsPerSecond10,
            bottom_panel: BottomPanel::Console,
            loaded_program: LoadedProgram::default(),
            load_error: None,
        }
    }
}

impl Lc3DesktopApp {
    fn new(creation_context: &eframe::CreationContext<'_>) -> Self {
        creation_context
            .egui_ctx
            .set_visuals(egui::Visuals::light());
        creation_context.egui_ctx.set_zoom_factor(1.25);
        Self::default()
    }
}

impl eframe::App for Lc3DesktopApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::TopBottomPanel::top("toolbar").show(ctx, |ui| self.show_toolbar(ui));
        egui::TopBottomPanel::bottom("bottom_panes")
            .resizable(true)
            .default_height(150.0)
            .height_range(92.0..=260.0)
            .show(ctx, |ui| self.show_bottom_panes(ui));

        egui::SidePanel::left("step_history")
            .resizable(false)
            .default_width(220.0)
            .width_range(180.0..=300.0)
            .show(ctx, Self::show_step_history);

        egui::SidePanel::right("machine_state")
            .resizable(false)
            .default_width(220.0)
            .width_range(190.0..=300.0)
            .show(ctx, Self::show_machine_state);

        egui::CentralPanel::default().show(ctx, |ui| self.show_source(ui));
    }
}

impl Lc3DesktopApp {
    fn show_toolbar(&mut self, ui: &mut egui::Ui) {
        ui.add_space(4.0);
        ui.horizontal(|ui| {
            if ui.button("Open").clicked()
                && let Some(path) = rfd::FileDialog::new()
                    .add_filter("Assembly", &["asm"])
                    .pick_file()
            {
                self.load_error =
                    open_program_paths(&mut self.loaded_program, std::slice::from_ref(&path))
                        .err()
                        .map(|error| error.to_string());
            }

            let _ = ui.button("Reset");
            let _ = ui.button("Step");
            let _ = ui.button("Run");
            let _ = ui.button("Stop");

            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                egui::ComboBox::from_id_salt("speed")
                    .selected_text(self.speed.label())
                    .show_ui(ui, |ui| {
                        for speed in ExecutionSpeed::ALL {
                            ui.selectable_value(&mut self.speed, speed, speed.label());
                        }
                    });

                ui.label("Speed");
            });
        });

        if let Some(loaded) = self.loaded_program.assemblies.last() {
            ui.add_space(2.0);
            ui.label(format!("Program: {}", loaded.path.display()));
        }

        if let Some(error) = &self.load_error {
            ui.add_space(2.0);
            ui.colored_label(
                ui.visuals().error_fg_color,
                format!("Failed to open program: {error}"),
            );
        }

        ui.add_space(4.0);
    }

    fn show_step_history(ui: &mut egui::Ui) {
        ui.heading("Step History");
        ui.separator();

        if let Some(current) = HISTORY_ITEMS.first() {
            egui::Frame::group(ui.style())
                .stroke(egui::Stroke::new(2.0_f32, ui.visuals().strong_text_color()))
                .show(ui, |ui| {
                    ui.set_width(ui.available_width());
                    ui.label(egui::RichText::new("Current").strong());
                    ui.add_space(6.0);
                    show_history_item(ui, current);
                });
        }

        ui.add_space(10.0);

        egui::ScrollArea::vertical().show(ui, |ui| {
            for item in &HISTORY_ITEMS[1..] {
                egui::Frame::group(ui.style()).show(ui, |ui| {
                    ui.set_width(ui.available_width());
                    show_history_item(ui, item);
                });
                ui.add_space(6.0);
            }
        });
    }

    fn show_source(&self, ui: &mut egui::Ui) {
        const LINE_WIDTH: f32 = 44.0;
        const ADDRESS_WIDTH: f32 = 76.0;
        const MACHINE_WIDTH: f32 = 150.0;
        const COLUMN_SPACING: f32 = 8.0;

        ui.heading("Source Code");
        ui.separator();

        let Some(loaded) = self.loaded_program.assemblies.last() else {
            ui.label("Open an assembly file to view its source.");
            return;
        };

        for diagnostic in &loaded.assembly.diagnostics {
            ui.colored_label(ui.visuals().error_fg_color, diagnostic.to_string());
        }

        let fixed_width = LINE_WIDTH + ADDRESS_WIDTH + MACHINE_WIDTH + COLUMN_SPACING * 3.0;
        let source_width = (ui.available_width() - fixed_width).max(120.0);

        egui::ScrollArea::both()
            .auto_shrink([false; 2])
            .show(ui, |ui| {
                egui::Grid::new("source_grid")
                    .striped(true)
                    .spacing([COLUMN_SPACING, 6.0])
                    .show(ui, |ui| {
                        show_source_header(ui, "Line", LINE_WIDTH);
                        show_source_header(ui, "Address", ADDRESS_WIDTH);
                        show_source_header(ui, "Source", source_width);
                        show_source_header(ui, "Machine", MACHINE_WIDTH);
                        ui.end_row();

                        for row in source_rows(&loaded.assembly) {
                            show_source_row(
                                ui,
                                &row,
                                LINE_WIDTH,
                                ADDRESS_WIDTH,
                                source_width,
                                MACHINE_WIDTH,
                            );
                        }
                    });
            });
    }

    fn show_machine_state(ui: &mut egui::Ui) {
        ui.heading("Registers");
        ui.separator();

        egui::Grid::new("registers_grid")
            .striped(true)
            .spacing([14.0, 6.0])
            .show(ui, |ui| {
                ui.strong("Reg");
                ui.strong("Value");
                ui.end_row();

                for register in REGISTERS {
                    ui.label(register.name);
                    show_change_cell(ui, register.value, register.previous);
                    ui.end_row();
                }
            });

        ui.add_space(14.0);
        ui.heading("Condition Codes");
        ui.separator();
        egui::Grid::new("condition_codes_grid")
            .spacing([18.0, 4.0])
            .show(ui, |ui| {
                for name in ["N", "Z", "P"] {
                    ui.strong(name);
                }
                ui.end_row();

                ui.monospace("0");
                show_change_cell(ui, "0", Some("1"));
                show_change_cell(ui, "1", Some("0"));
                ui.end_row();
            });

        ui.add_space(14.0);
        ui.horizontal(|ui| {
            ui.heading("Watch");
            ui.separator();
            ui.label("Symbols");
        });
        ui.separator();

        egui::Grid::new("symbols_grid")
            .striped(true)
            .spacing([18.0, 6.0])
            .show(ui, |ui| {
                ui.strong("Name");
                ui.strong("Value");
                ui.end_row();

                for (name, value) in SYMBOLS {
                    ui.label(*name);
                    ui.label(*value);
                    ui.end_row();
                }
            });
    }

    fn show_bottom_panes(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| {
            for panel in BottomPanel::ALL {
                ui.selectable_value(&mut self.bottom_panel, panel, panel.label());
            }
        });

        ui.separator();

        match self.bottom_panel {
            BottomPanel::Console => show_console(ui),
            BottomPanel::Memory => show_memory(ui),
            BottomPanel::ImageBuffer => show_image_buffer(ui),
            BottomPanel::Command => show_command(ui),
        }
    }
}

#[derive(Clone, Copy)]
struct HistoryItem {
    step: &'static str,
    address: &'static str,
    instruction: &'static str,
    summary: &'static str,
}

impl HistoryItem {
    const fn new(
        step: &'static str,
        address: &'static str,
        instruction: &'static str,
        summary: &'static str,
    ) -> Self {
        Self {
            step,
            address,
            instruction,
            summary,
        }
    }
}

#[derive(Clone, Copy)]
struct RegisterRow {
    name: &'static str,
    value: &'static str,
    previous: Option<&'static str>,
}

impl RegisterRow {
    const fn new(name: &'static str, value: &'static str, previous: Option<&'static str>) -> Self {
        Self {
            name,
            value,
            previous,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum BottomPanel {
    Console,
    Memory,
    ImageBuffer,
    Command,
}

impl BottomPanel {
    const ALL: [Self; 4] = [
        Self::Console,
        Self::Memory,
        Self::ImageBuffer,
        Self::Command,
    ];

    const fn label(self) -> &'static str {
        match self {
            Self::Console => "Console",
            Self::Memory => "Memory",
            Self::ImageBuffer => "Image Buffer",
            Self::Command => "Command",
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum ExecutionSpeed {
    SingleStep,
    StepsPerSecond1,
    StepsPerSecond10,
    Unlimited,
}

impl ExecutionSpeed {
    const ALL: [Self; 4] = [
        Self::SingleStep,
        Self::StepsPerSecond1,
        Self::StepsPerSecond10,
        Self::Unlimited,
    ];

    const fn label(self) -> &'static str {
        match self {
            Self::SingleStep => "Manual",
            Self::StepsPerSecond1 => "1 step/sec",
            Self::StepsPerSecond10 => "10 steps/sec",
            Self::Unlimited => "Unlimited",
        }
    }
}

fn show_history_item(ui: &mut egui::Ui, item: &HistoryItem) {
    ui.label(egui::RichText::new(item.step).strong());
    ui.monospace(format!("{}  {}", item.address, item.instruction));
    ui.monospace(item.summary);
}

fn show_source_header(ui: &mut egui::Ui, text: &str, width: f32) {
    ui.add_sized(
        [width, ui.spacing().interact_size.y],
        egui::Label::new(egui::RichText::new(text).strong()).truncate(),
    );
}

fn show_source_row(
    ui: &mut egui::Ui,
    row: &SourceRow<'_>,
    line_width: f32,
    address_width: f32,
    source_width: f32,
    machine_width: f32,
) {
    let row_height = ui.spacing().interact_size.y;
    let address = if let Some(address) = row.address {
        format!("x{address:04X}")
    } else {
        "--".to_owned()
    };
    let machine = format_machine_words(row.words);

    ui.add_sized(
        [line_width, row_height],
        egui::Label::new(row.line.to_string()),
    );
    ui.add_sized(
        [address_width, row_height],
        egui::Label::new(egui::RichText::new(address).monospace()).truncate(),
    );
    ui.add_sized(
        [source_width, row_height],
        egui::Label::new(egui::RichText::new(row.source).monospace()).truncate(),
    );
    ui.add_sized(
        [machine_width, row_height],
        egui::Label::new(egui::RichText::new(&machine).monospace()).truncate(),
    );
    ui.end_row();
}

fn format_machine_words(words: &[u16]) -> String {
    const PREVIEW_WORDS: usize = 4;

    if words.is_empty() {
        return "--".to_owned();
    }

    let mut machine = words
        .iter()
        .take(PREVIEW_WORDS)
        .map(|word| format!("{word:04X}"))
        .collect::<Vec<_>>()
        .join(" ");

    if words.len() > PREVIEW_WORDS {
        machine.push_str(&format!(" … (+{})", words.len() - PREVIEW_WORDS));
    }

    machine
}

fn show_change_cell(ui: &mut egui::Ui, value: &str, previous: Option<&str>) {
    if let Some(previous) = previous {
        let response = ui.add(
            egui::Button::new(egui::RichText::new(value).monospace())
                .selected(true)
                .frame(true),
        );
        response.on_hover_text(format!("previous: {previous}"));
    } else {
        ui.monospace(value);
    }
}

fn show_console(ui: &mut egui::Ui) {
    ui.label("Welcome to the LC-3 Teaching Simulator.");
    ui.label("Program output will appear here.");
    ui.monospace("> 42");
    ui.add_space(8.0);
    ui.horizontal(|ui| {
        let mut input = String::new();
        ui.add(
            egui::TextEdit::singleline(&mut input)
                .hint_text("Enter input...")
                .desired_width(f32::INFINITY),
        );
        let _ = ui.button("Enter");
    });
}

fn show_memory(ui: &mut egui::Ui) {
    egui::Grid::new("memory_grid")
        .striped(true)
        .spacing([18.0, 6.0])
        .show(ui, |ui| {
            ui.strong("Address");
            for offset in 0..8 {
                ui.strong(format!("+{offset}"));
            }
            ui.end_row();

            for row in [
                (
                    "x2FF8",
                    [
                        "x0000", "x0000", "x0000", "x0000", "x0000", "x0000", "x0000", "x0000",
                    ],
                ),
                (
                    "x3000",
                    [
                        "x1021", "x5260", "x1261", "x1021", "x6860", "x0401", "x0BFD", "x1261",
                    ],
                ),
                (
                    "x3008",
                    [
                        "x7860", "x0BF7", "xF025", "x0000", "x300B", "x0000", "x0000", "x0000",
                    ],
                ),
            ] {
                ui.label(row.0);
                for value in row.1 {
                    ui.monospace(value);
                }
                ui.end_row();
            }
        });
}

fn show_image_buffer(ui: &mut egui::Ui) {
    ui.vertical_centered(|ui| {
        ui.label("Image buffer preview");
        ui.add_space(8.0);
        let (rect, _) = ui.allocate_exact_size(egui::vec2(320.0, 90.0), egui::Sense::hover());
        ui.painter().rect_stroke(
            rect,
            0.0,
            egui::Stroke::new(1.0_f32, ui.visuals().widgets.inactive.fg_stroke.color),
            egui::StrokeKind::Inside,
        );
        ui.painter().text(
            rect.center(),
            egui::Align2::CENTER_CENTER,
            "framebuffer",
            egui::TextStyle::Monospace.resolve(ui.style()),
            ui.visuals().weak_text_color(),
        );
    });
}

fn show_command(ui: &mut egui::Ui) {
    ui.monospace("Commands might live here later: break x3005, mem x3000, step 10, run");
}

fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([1320.0, 840.0])
            .with_min_inner_size([960.0, 640.0]),
        ..Default::default()
    };

    eframe::run_native(
        "LC-3 Simulator",
        options,
        Box::new(|creation_context| Ok(Box::new(Lc3DesktopApp::new(creation_context)))),
    )
}
