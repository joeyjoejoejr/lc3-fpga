#include "lc3_sim_core.h"
#include <cstdint>
#include "lc3_sim_ffi.h"

struct Lc3Sim {
  lc3::sim::Simulator sim;
  std::uint64_t max_cycles;

  explicit Lc3Sim(std::uint16_t reset_pc, std::uint64_t max_cycles)
    : sim(reset_pc), max_cycles(max_cycles) {}
};

extern "C" Lc3Sim* lc3_sim_new(uint16_t reset_pc, uint64_t max_cycles) {
  try {
    return new Lc3Sim(reset_pc, max_cycles);
  } catch (...) {
    return nullptr;
  }
}

extern "C" void lc3_sim_free(Lc3Sim* sim) {
  if (sim == nullptr) return;

  delete sim;
}

extern "C" int lc3_load_image(Lc3Sim* sim, const uint8_t* bytes, size_t len) {
  if(sim == nullptr || bytes == nullptr) return 2;

  try {
    sim->sim.load_dense_image(bytes, len);
    return 0;
  } catch (...) {
    return 1;
  }
}

extern "C" int lc3_sim_run(Lc3Sim* sim, Lc3RunReport* report) {
  if(sim == nullptr || report == nullptr) return 2;

  try {
    lc3::sim::RunReport run_report = sim->sim.run_cycles(sim->max_cycles);
    report->pc = run_report.pc;
    report->ir = run_report.ir;
    report->cycles = run_report.cycles;
    return 0;
  } catch(...) {
    return 1;
  }
}
