#!/bin/bash
# ==============================================================================
# Script para compilar el informe Markdown a PDF en formato A4 (GOYS TP4)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Compilando Markdown a HTML con estilos de impresión..."
pandoc entrega-modalidad-a.md --css print.css --standalone -o entrega-modalidad-a.html

echo "Generando PDF con WeasyPrint en tamaño A4..."
~/.local/bin/weasyprint entrega-modalidad-a.html entrega-modalidad-a.pdf

PAGES=$(pdfinfo entrega-modalidad-a.pdf | grep "Pages:" | awk '{print $2}')
SIZE=$(du -h entrega-modalidad-a.pdf | awk '{print $1}')

echo "PDF generado exitosamente:"
echo "  - Archivo: $DIR/entrega-modalidad-a.pdf"
echo "  - Páginas: $PAGES (Requerido por cátedra: 5 a 7 páginas)"
echo "  - Tamaño: $SIZE"
