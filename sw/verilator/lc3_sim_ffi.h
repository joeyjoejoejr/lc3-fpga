#pragma once

#include <cstddef>
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif
  typedef struct Lc3Sim Lc3Sim;
  
  typedef struct {
    uint16_t pc;
    uint16_t ir;
    uint64_t cycles;
  } Lc3RunReport;

  Lc3Sim* lc3_sim_new(uint16_t reset_pc, uint64_t max_cycles);
  void lc3_sim_free(Lc3Sim* sim);
  int lc3_load_image(Lc3Sim* sim, const uint8_t* bytes, size_t len);
  int lc3_sim_run(Lc3Sim* sim, Lc3RunReport* report);

#ifdef __cplusplus
}
#endif
