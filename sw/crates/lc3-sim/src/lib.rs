use std::fmt::Display;

#[cfg(feature = "verilator")]
use std::ptr::NonNull;

use lc3_image::DenseMemoryImage;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Default)]
pub struct RunReport {
    pub pc: u16,
    pub ir: u16,
    pub cycles: u64,
}

impl Display for RunReport {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "pc: x{:04X}, ir: x{:04X}, cycles {}",
            self.pc, self.ir, self.cycles
        )
    }
}

#[derive(Debug, Eq, PartialEq)]
pub enum SimulatorError {
    NotImplemented,
    CreateFailed,
    InvalidArgument,
    RuntimeError,
    UnknownStatus(usize),
}

impl Display for SimulatorError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotImplemented => write!(f, "simulator backend is not implemented"),
            Self::CreateFailed => write!(f, "failed to create simulator"),
            Self::InvalidArgument => write!(f, "invalid simulator argument"),
            Self::RuntimeError => write!(f, "simulator runtime error"),
            Self::UnknownStatus(status) => write!(f, "unknown simulator status: {status}"),
        }
    }
}

#[cfg(feature = "verilator")]
pub struct Simulator {
    raw: NonNull<ffi::Lc3Sim>,
}

#[cfg(not(feature = "verilator"))]
pub struct Simulator {
    _reset_pc: u16,
    _max_cycles: Option<u64>,
}

#[cfg(feature = "verilator")]
impl Simulator {
    #[must_use]
    pub fn new(reset_pc: u16, max_cycles: Option<u64>) -> Result<Self, SimulatorError> {
        let max_cycles = max_cycles.unwrap_or(0);
        let raw = unsafe { ffi::lc3_sim_new(reset_pc, max_cycles) };
        let raw = NonNull::new(raw).ok_or(SimulatorError::CreateFailed)?;
        Ok(Self { raw })
    }

    /// Load a dense LC-3 memory image into the simulator.
    ///
    /// # Errors
    ///
    /// Returns an error until the simulator backend is implemented.
    pub fn load_dense_image(&mut self, image: &DenseMemoryImage) -> Result<(), SimulatorError> {
        let status = unsafe {
            ffi::lc3_load_image(
                self.raw.as_ptr(),
                image.be_bytes().as_ptr(),
                image.be_bytes().len(),
            )
        };

        ffi_status_to_result(status)
    }

    /// Run the simulator according to its configuration.
    ///
    /// # Errors
    ///
    /// Returns an error until the simulator backend is implemented.
    pub fn run(&mut self) -> Result<RunReport, SimulatorError> {
        let mut raw_report = ffi::Lc3RunReport {
            pc: 0,
            ir: 0,
            cycles: 0,
        };

        let status = unsafe { ffi::lc3_sim_run(self.raw.as_ptr(), &mut raw_report) };

        ffi_status_to_result(status)?;

        Ok(RunReport {
            pc: raw_report.pc,
            ir: raw_report.ir,
            cycles: raw_report.cycles,
        })
    }
}

#[cfg(feature = "verilator")]
fn ffi_status_to_result(status: usize) -> Result<(), SimulatorError> {
    match status {
        0 => Ok(()),
        1 => Err(SimulatorError::RuntimeError),
        2 => Err(SimulatorError::InvalidArgument),
        status => Err(SimulatorError::UnknownStatus(status)),
    }
}

#[cfg(not(feature = "verilator"))]
impl Simulator {
    /// Create a simulator handle.
    ///
    /// # Errors
    ///
    /// The default backend does not currently fail during construction.
    pub const fn new(reset_pc: u16, max_cycles: Option<u64>) -> Result<Self, SimulatorError> {
        Ok(Self {
            _reset_pc: reset_pc,
            _max_cycles: max_cycles,
        })
    }

    /// Load a dense LC-3 memory image into the simulator.
    ///
    /// # Errors
    ///
    /// Returns an error until the Verilator backend feature is enabled.
    pub const fn load_dense_image(
        &mut self,
        _image: &DenseMemoryImage,
    ) -> Result<(), SimulatorError> {
        Err(SimulatorError::NotImplemented)
    }

    /// Run the simulator according to its configuration.
    ///
    /// # Errors
    ///
    /// Returns an error until the Verilator backend feature is enabled.
    pub const fn run(&mut self) -> Result<RunReport, SimulatorError> {
        Err(SimulatorError::NotImplemented)
    }
}

#[cfg(feature = "verilator")]
impl Drop for Simulator {
    fn drop(&mut self) {
        unsafe {
            ffi::lc3_sim_free(self.raw.as_ptr());
        };
    }
}

#[cfg(feature = "verilator")]
mod ffi {
    use std::ffi::{c_uchar, c_ulonglong};

    pub enum Lc3Sim {}

    #[repr(C)]
    pub struct Lc3RunReport {
        pub pc: u16,
        pub ir: u16,
        pub cycles: u64,
    }

    unsafe extern "C" {
        pub fn lc3_sim_new(reset_pc: u16, max_cycles: c_ulonglong) -> *mut Lc3Sim;
        pub fn lc3_sim_free(sim: *mut Lc3Sim);
        pub fn lc3_load_image(sim: *mut Lc3Sim, bytes: *const c_uchar, len: usize) -> usize;
        pub fn lc3_sim_run(sim: *mut Lc3Sim, report: *mut Lc3RunReport) -> usize;
    }
}
