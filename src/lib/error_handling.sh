#!/bin/bash
trap 'log_error "Ocurrió un error en la línea $LINENO"' ERR
