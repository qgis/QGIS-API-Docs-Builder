# ═══════════════════════════════════════════════════════════════════════════════
# QGIS API Documentation - Release Configuration
# ═══════════════════════════════════════════════════════════════════════════════
#
# This file defines which QGIS releases to build documentation for.
#
# Build methods:
#   - useLegacyBuild = false: Uses QGIS flake's docs package (fast, cached)
#   - useLegacyBuild = true:  Uses CMake/Doxygen directly (for older releases)
#
# Lower order number = shown first in the index.
#
# Made with 💗 by Kartoza | https://kartoza.com
#
# ═══════════════════════════════════════════════════════════════════════════════

{
  # ═══════════════════════════════════════════════════════════════════════════
  # Master branch (nightly/development)
  # ═══════════════════════════════════════════════════════════════════════════
  master = {
    branch = "master";
    version = "master";
    label = "Master (Development)";
    isLTS = false;
    isLatest = false;
    isMaster = true;
    useLegacyBuild = false;
    order = 0;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 4.x Series
  # ═══════════════════════════════════════════════════════════════════════════
  "4_0" = {
    branch = "release-4_0";
    version = "4.0";
    label = "4.0";
    isLTS = false;
    isLatest = true;
    isMaster = false;
    useLegacyBuild = false;
    order = 1;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 3.x Series (flake-based builds for 3.40+)
  # ═══════════════════════════════════════════════════════════════════════════
  "3_44" = {
    branch = "release-3_44";
    version = "3.44";
    label = "3.44";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = false;
    order = 2;
  };

  "3_42" = {
    branch = "release-3_42";
    version = "3.42";
    label = "3.42";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = false;
    order = 3;
  };

  "3_40" = {
    branch = "release-3_40";
    version = "3.40";
    label = "3.40 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = false;
    order = 4;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 3.x Series (legacy CMake/Doxygen builds)
  # ═══════════════════════════════════════════════════════════════════════════
  "3_38" = {
    branch = "release-3_38";
    version = "3.38";
    label = "3.38";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 5;
  };

  "3_36" = {
    branch = "release-3_36";
    version = "3.36";
    label = "3.36";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 6;
  };

  "3_34" = {
    branch = "release-3_34";
    version = "3.34";
    label = "3.34 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 7;
  };

  "3_32" = {
    branch = "release-3_32";
    version = "3.32";
    label = "3.32";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 8;
  };

  "3_30" = {
    branch = "release-3_30";
    version = "3.30";
    label = "3.30";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 9;
  };

  "3_28" = {
    branch = "release-3_28";
    version = "3.28";
    label = "3.28 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 10;
  };

  "3_26" = {
    branch = "release-3_26";
    version = "3.26";
    label = "3.26";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 11;
  };

  "3_24" = {
    branch = "release-3_24";
    version = "3.24";
    label = "3.24";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 12;
  };

  "3_22" = {
    branch = "release-3_22";
    version = "3.22";
    label = "3.22 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 13;
  };

  "3_20" = {
    branch = "release-3_20";
    version = "3.20";
    label = "3.20";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 14;
  };

  "3_18" = {
    branch = "release-3_18";
    version = "3.18";
    label = "3.18";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 15;
  };

  "3_16" = {
    branch = "release-3_16";
    version = "3.16";
    label = "3.16 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 16;
  };

  "3_14" = {
    branch = "release-3_14";
    version = "3.14";
    label = "3.14";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 17;
  };

  "3_12" = {
    branch = "release-3_12";
    version = "3.12";
    label = "3.12";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 18;
  };

  "3_10" = {
    branch = "release-3_10";
    version = "3.10";
    label = "3.10 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 19;
  };

  "3_8" = {
    branch = "release-3_8";
    version = "3.8";
    label = "3.8";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 20;
  };

  "3_6" = {
    branch = "release-3_6";
    version = "3.6";
    label = "3.6";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 21;
  };

  "3_4" = {
    branch = "release-3_4";
    version = "3.4";
    label = "3.4 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 22;
  };

  "3_2" = {
    branch = "release-3_2";
    version = "3.2";
    label = "3.2";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 23;
  };

  "3_0" = {
    branch = "release-3_0";
    version = "3.0";
    label = "3.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 24;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 2.x Series (legacy)
  # ═══════════════════════════════════════════════════════════════════════════
  "2_18" = {
    branch = "release-2_18";
    version = "2.18";
    label = "2.18 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 25;
  };

  "2_16" = {
    branch = "release-2_16";
    version = "2.16";
    label = "2.16";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 26;
  };

  "2_14" = {
    branch = "release-2_14";
    version = "2.14";
    label = "2.14 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 27;
  };

  "2_12" = {
    branch = "release-2_12";
    version = "2.12";
    label = "2.12";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 28;
  };

  "2_10" = {
    branch = "release-2_10";
    version = "2.10";
    label = "2.10";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 29;
  };

  "2_8" = {
    branch = "release-2_8";
    version = "2.8";
    label = "2.8 LTS";
    isLTS = true;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 30;
  };

  "2_6" = {
    branch = "release-2_6";
    version = "2.6";
    label = "2.6";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 31;
  };

  "2_4" = {
    branch = "release-2_4";
    version = "2.4";
    label = "2.4";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 32;
  };

  "2_0" = {
    branch = "release-2_0";
    version = "2.0";
    label = "2.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 33;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 1.x Series (legacy/historical)
  # ═══════════════════════════════════════════════════════════════════════════
  "1_8" = {
    branch = "release-1_8";
    version = "1.8";
    label = "1.8";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 34;
  };

  "1_7" = {
    branch = "release-1_7";
    version = "1.7";
    label = "1.7";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 35;
  };

  "1_6_0" = {
    branch = "release-1_6_0";
    version = "1.6.0";
    label = "1.6.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 36;
  };

  "1_5_0" = {
    branch = "release-1_5_0";
    version = "1.5.0";
    label = "1.5.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 37;
  };

  "1_4_0" = {
    branch = "release-1_4_0";
    version = "1.4.0";
    label = "1.4.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 38;
  };

  "1_3_0" = {
    branch = "release-1_3_0";
    version = "1.3.0";
    label = "1.3.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 39;
  };

  "1_2_0" = {
    branch = "release-1_2_0";
    version = "1.2.0";
    label = "1.2.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 40;
  };

  "1_1_0" = {
    branch = "release-1_1_0";
    version = "1.1.0";
    label = "1.1.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 41;
  };

  "1_0_0" = {
    branch = "release-1_0_0";
    version = "1.0.0";
    label = "1.0.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 42;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # QGIS 0.x Series (historical/archival)
  # ═══════════════════════════════════════════════════════════════════════════
  "0_11_0" = {
    branch = "release-0_11_0";
    version = "0.11.0";
    label = "0.11.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 43;
  };

  "0_10_0" = {
    branch = "release-0_10_0";
    version = "0.10.0";
    label = "0.10.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 44;
  };

  "0_9_1" = {
    branch = "release-0_9_1";
    version = "0.9.1";
    label = "0.9.1";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 45;
  };

  "0_8_1" = {
    branch = "release-0_8_1";
    version = "0.8.1";
    label = "0.8.1";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 46;
  };

  "0_8_0" = {
    branch = "release-0_8_0";
    version = "0.8.0";
    label = "0.8.0";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 47;
  };

  "0_6" = {
    branch = "release-0_6";
    version = "0.6";
    label = "0.6";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 48;
  };

  "0_5" = {
    branch = "release-0_5";
    version = "0.5";
    label = "0.5";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 49;
  };

  "0_4" = {
    branch = "release-0_4";
    version = "0.4";
    label = "0.4";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 50;
  };

  "0_3" = {
    branch = "release-0_3";
    version = "0.3";
    label = "0.3";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 51;
  };

  "0_2" = {
    branch = "release-0_2";
    version = "0.2";
    label = "0.2";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 52;
  };

  "0_1" = {
    branch = "release-0_1";
    version = "0.1";
    label = "0.1";
    isLTS = false;
    isLatest = false;
    isMaster = false;
    useLegacyBuild = true;
    order = 53;
  };
}
