### 0.1.1



* Note that `mvgAddCGPath` is exported as a global via ``MULLE_CG_NANOVG_GLOBAL``
* Note that all functions in `CGContext+DrawingConveniences.h` are exported as globals via ``MULLE_CG_NANOVG_GLOBAL``


* add `add_subdirectory()` support so an external project can embed this library and inherit its staged headers, include directories and link dependencies
* `find_package()` config now resolves dependencies by name and re-exports them as imported targets, so consumers no longer have to name every dependency themselves
* add a force-link (whole-archive) wrapper so libraries with atinit/atexit constructors are fully linked into consumers
* Windows executables embed a UTF-8 activeCodePage manifest so argv and the environment arrive as UTF-8

## 0.1.0




* **BREAKING** `CGContextBase +createPathContext` renamed to `+pathContext`
* add internal CGColor`<->`NVGcolor zero-cost conversion header
* add standard BSD license headers to all project sources
