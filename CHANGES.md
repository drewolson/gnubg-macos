# Fork Changes

This document tracks all modifications made to GNU Backgammon 1.08.003 in this fork.

## Format
Each entry should include:
- Date of change
- Description of what was changed
- Reason for the change
- Files affected

---

## 2025-10-14 - Initial Fork Setup

**Changes:**
- Initialized git repository
- Created FORK.md to document fork purpose and maintenance strategy
- Created this CHANGES.md file to track modifications

**Reason:**
Establishing proper version control and documentation for macOS-specific fork

**Files affected:**
- `.git/` (new)
- `FORK.md` (new)
- `CHANGES.md` (new)

---

## 2025-10-14 - macOS Readline Compatibility Fix

**Changes:**
- Modified readline initialization in gnubg.c to fix compilation on macOS
- Changed `rl_filename_quote_characters = szCommandSeparators` to only set `rl_basic_word_break_characters`
- Changed `rl_completion_entry_function = NullGenerator` to `rl_completion_entry_function = NULL`

**Reason:**
Modern macOS readline library has different function signature expectations. The `rl_filename_quote_characters` assignment was causing build issues, and `NullGenerator` should be NULL for proper readline 4.2+ compatibility on macOS.

**Files affected:**
- `gnubg.c` (line 4403, 4406)

---

## 2025-10-14 - Added cglm Graphics Library

**Changes:**
- Added complete cglm (OpenGL Mathematics) library to the project
- Includes headers for matrix operations, vectors, quaternions, affine transforms, camera operations, and other 3D math utilities
- Added Apple Silicon SIMD optimizations (applesimd.h)

**Reason:**
Required for 3D board rendering and graphics operations. The cglm library provides optimized math operations for OpenGL-based rendering, with specific support for macOS/Apple Silicon SIMD instructions.

**Files affected:**
- `cglm/` (entire directory - new, ~200+ header files)
- Includes core functionality in cglm/*.h
- SIMD optimizations in cglm/simd/
- Structured API in cglm/struct/
- Platform-specific optimizations in cglm/applesimd.h

---

## Future Changes

All future modifications should be documented here with the same format:
- Date
- Description
- Reason
- Files affected
