#!/bin/bash
# ==============================================================================
# Script para compilar el informe Markdown a PDF en formato A4 (GOYS TP4)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

TMP_HTML=".tmp-entrega-modalidad-a.html"
trap 'rm -f "$TMP_HTML"' EXIT

echo "Compilando Markdown a HTML temporal con estilos de impresión..."
pandoc entrega-modalidad-a.md --css print.css --standalone -o "$TMP_HTML"

echo "Generando PDF con WeasyPrint en tamaño A4..."
~/.local/bin/weasyprint "$TMP_HTML" entrega-modalidad-a.pdf

PAGES=$(pdfinfo entrega-modalidad-a.pdf | grep "Pages:" | awk '{print $2}')
SIZE=$(du -h entrega-modalidad-a.pdf | awk '{print $1}')

echo "PDF generado exitosamente:"
echo "  - Archivo: $DIR/entrega-modalidad-a.pdf"
echo "  - Páginas: $PAGES (Requerido por cátedra: 5 a 7 páginas)"
echo "  - Tamaño: $SIZE"
