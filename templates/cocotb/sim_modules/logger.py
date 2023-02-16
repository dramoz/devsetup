#####################################################################################
#  File: tb_class.py
#  Copyright (c) 2022 Eidetic Communications Inc.
#  All rights reserved.
#  This license message must appear in all versions of this code including
#  modified versions.
#  BSD 3-Clause
####################################################################################
# Overview:
"""
TB Base Class
"""
# -----------------------------------------------------------------------------
import sys, os
import logging
from pathlib import Path

# -----------------------------------------------------------------------------
from cocotb.log import SimColourLogFormatter
import cocotb.ANSI as ANSI
from haggis.logs import add_logging_level
# -----------------------------------------------------------------------------
def add_logging_lvl(name, level, color):
  color = color + "%s" + ANSI.COLOR_DEFAULT
  level = logging.CRITICAL - 1
  add_logging_level(name, level)
  SimColourLogFormatter.loglevel2colour[level] = color
  