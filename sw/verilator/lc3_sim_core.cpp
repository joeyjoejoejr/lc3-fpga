#include "lc3_sim_core.h"

#include "Vlc3_verilator_top.h"

#include "verilated.h"

#include <stdexcept>

double sc_time_stamp() {
  return 0;
}

namespace lc3::sim {
namespace {

constexpr std::size_t kMemoryWordCount = 65536;
constexpr std::size_t kMemoryByteCount = kMemoryWordCount * 2;

}  // namespace

struct Simulator::Impl {
  VerilatedContext context;
  Vlc3_verilator_top top;

  explicit Impl(std::uint16_t reset_pc) : top{&context} {
    top.clk = 0;
    top.reset = 1;
    top.loader_we = 0;
    top.reset_pc = reset_pc;

    tick();
  }

  ~Impl() { top.final(); }

  void tick() {
    top.clk = 0;
    top.eval();
    context.timeInc(5);

    top.clk = 1;
    top.eval();
    context.timeInc(5);
  }
};

Simulator::Simulator(std::uint16_t reset_pc) : impl_{std::make_unique<Impl>(reset_pc)} {}

Simulator::~Simulator() = default;

Simulator::Simulator(Simulator&&) noexcept = default;

Simulator& Simulator::operator=(Simulator&&) noexcept = default;

void Simulator::command_args(int argc, char** argv) {
  impl_->context.commandArgs(argc, argv);
}

void Simulator::load_dense_image(const std::uint8_t* bytes, std::size_t len) {
  if (bytes == nullptr) {
    throw std::runtime_error("memory image pointer must not be null");
  }

  if (len != kMemoryByteCount) {
    throw std::runtime_error("memory image must be exactly 131072 bytes");
  }

  for (std::size_t addr = 0; addr < kMemoryWordCount; ++addr) {
    const std::size_t i = addr * 2;
    const std::uint16_t word = (static_cast<std::uint16_t>(bytes[i]) << 8)
                               | static_cast<std::uint16_t>(bytes[i + 1]);

    impl_->top.loader_addr = addr;
    impl_->top.loader_wdata = word;
    impl_->top.loader_we = 1;
    impl_->tick();
  }

  impl_->top.loader_we = 0;
  impl_->top.reset = 0;
}

RunReport Simulator::run_cycles(std::uint64_t max_cycles) {
  std::uint64_t cycle = 0;

  while (!impl_->top.halted && (max_cycles == 0 || cycle < max_cycles) && !impl_->context.gotFinish()) {
    impl_->tick();
    cycle++;
  }

  return RunReport{
      .pc = impl_->top.pc,
      .ir = impl_->top.ir,
      .psr = impl_->top.psr,
      .cycles = cycle,
  };
}

}  // namespace lc3::sim
