#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>

namespace lc3::sim {

struct RunReport {
  std::uint16_t pc = 0;
  std::uint16_t ir = 0;
  std::uint16_t psr = 0;
  std::uint64_t cycles = 0;
};

class Simulator {
 public:
  explicit Simulator(std::uint16_t reset_pc);
  ~Simulator();

  Simulator(const Simulator&) = delete;
  Simulator& operator=(const Simulator&) = delete;
  Simulator(Simulator&&) noexcept;
  Simulator& operator=(Simulator&&) noexcept;

  void command_args(int argc, char** argv);
  void load_dense_image(const std::uint8_t* bytes, std::size_t len);
  RunReport run_cycles(std::uint64_t max_cycles);

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};

}  // namespace lc3::sim
