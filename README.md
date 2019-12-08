GhulbusVulkan - Third Party Dependencies
========================================

**Build status:** [![Build Status](https://travis-ci.org/ComicSansMS/GhulbusVulkanDependencies.svg?branch=master)](https://travis-ci.org/ComicSansMS/GhulbusVulkanDependencies)
[![Build status](https://ci.appveyor.com/api/projects/status/github/ComicSansMS/GhulbusVulkanDependencies?svg=true)](https://ci.appveyor.com/project/ComicSansMS/GhulbusVulkanDependencies)

Third party dependencies for the [GhulbusVulkan](https://github.com/ComicSansMS/GhulbusVulkan) library.

Prerequisites
-------------

CMake 3.13 or higher.

On Linux you will need the `xorg-dev` package.

Building
--------

`cmake -P build_dependencies.cmake`

You can specify the following options to customize the build:

  * `-DGENERATOR=<gen>` Uses `<gen>` as the CMake generator option (`-G` on the `cmake` command line)
  * `-DPLATFORM=<plt>` Uses `<plt>` as the CMake target platform option (`-A` on the `cmake` command line)
  * `-DTOOLSET=<tst>` Uses `<tst>` as the CMake toolset option (`-T` on the `cmake` command line)
  * `-DSKIP_GIT=ON` Prevents the script from automatically updating the git submodules before building
