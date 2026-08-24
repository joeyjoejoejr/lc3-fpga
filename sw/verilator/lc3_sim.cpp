#include "lc3_sim_core.h"

#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <ostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

constexpr std::size_t kMemoryWordCount = 65536;
constexpr std::size_t kMemoryByteCount = kMemoryWordCount * 2;

struct Args {
  std::string memory_path;
  std::uint16_t reset_pc = 0x3000;
  int cycles = 10;
};

std::vector<std::uint8_t> read_binary_file(const std::string& path) {
  std::ifstream file(path, std::ios::binary | std::ios::ate);

  if (!file) {
    throw std::runtime_error("failed to open file: " + path);
  }

  const std::streamsize size = file.tellg();

  if (size < 0) {
    throw std::runtime_error("failed to determine file size: : " + path);
  }

  std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size));


  file.seekg(0, std::ios::beg);
  if (!file.read(reinterpret_cast<char*>(bytes.data()), size)) {
    throw std::runtime_error("failed to read file: " + path);
  }

  return bytes;
}

std::string require_value(int argc, char** argv, int& index, const std::string& name) {
  if (index + 1 >= argc) {
    throw std::runtime_error(name + " requires a value");
  }

  ++index;
  return argv[index];
}

std::uint16_t parse_u16(const std::string& text, const std::string& name) {
  std::size_t parsed = 0;
  const unsigned long value = std::stoul(text, &parsed, 0);

  if (parsed != text.size() || value > std::numeric_limits<std::uint16_t>::max()) {
    throw std::runtime_error("invalid " + name + ": " + text);
  }

  return static_cast<std::uint16_t>(value);
}

int parse_cycles(const std::string& text) {
  std::size_t parsed = 0;
  const unsigned long value = std::stoul(text, &parsed, 0);

  if (parsed != text.size() || value > static_cast<unsigned long>(std::numeric_limits<int>::max())) {
    throw std::runtime_error("invalid --cycles: " + text);
  }

  return static_cast<int>(value);
}

Args parse_args(int argc, char** argv) {
  Args args;

  for (int i = 1; i < argc; ++i) {
    const std::string current = argv[i];

    if (!current.empty() && current[0] == '+') {
      continue;
    }

    if (current == "--memory") {
      args.memory_path = require_value(argc, argv, i, "--memory");
    } else if (current == "--reset-pc") {
      args.reset_pc = parse_u16(require_value(argc, argv, i, "--reset-pc"), "--reset-pc");
    } else if (current == "--cycles") {
      args.cycles = parse_cycles(require_value(argc, argv, i, "--cycles"));
    } else {
      throw std::runtime_error("unknown argument: " + current);
    }
  }

  if (args.memory_path.empty()) {
    throw std::runtime_error("--memory is required");
  }

  return args;
}

}  // namespace

int main(int argc, char** argv) {
  try {
    const Args args = parse_args(argc, argv);
    const std::vector<std::uint8_t> memory = read_binary_file(args.memory_path);

    if (memory.size() != kMemoryByteCount) {
      throw std::runtime_error("memory image must be exactly 131072 bytes");
    }

    lc3::sim::Simulator sim{args.reset_pc};
    sim.command_args(argc, argv);
    sim.load_dense_image(memory.data(), memory.size());
    std::cout << "loaded memory words=" << 0xFFFF + 1 << std::endl;

    const lc3::sim::RunReport report = sim.run_cycles(args.cycles);

    std::cout << "pc=0x" << std::hex << report.pc << " ir=0x" << report.ir
      << " psr=0x" << report.psr << '\n';

    return 0;
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << '\n';
    return 1;
  }
}
