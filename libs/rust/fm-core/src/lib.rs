//! # fm-core
//!
//! Framework-agnostic heart of the file manager, organised in three layers
//! following a hexagonal (ports & adapters) / DDD layout:
//!
//! * [`domain`] – entities, value objects, aggregates and the *ports*
//!   (traits) the domain needs from the outside world. Pure, no I/O.
//! * [`application`] – use cases that orchestrate the domain through ports.
//! * [`infrastructure`] – adapters implementing the ports with the real
//!   operating system (local filesystem, XDG user directories).
//!
//! Dependencies only point inwards: `infrastructure → application → domain`.
//! UI crates depend on `application` + `domain` and receive adapters through
//! their composition root.

pub mod application;
pub mod domain;
pub mod infrastructure;
