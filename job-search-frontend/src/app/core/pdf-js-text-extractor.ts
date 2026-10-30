import { Injectable } from '@angular/core';
import type { TextItem } from 'pdfjs-dist/types/src/display/api';
import { TextExtractor } from './text-extractor';
import { loadPdfJs } from './pdfjs';

@Injectable()
export class PdfJsTextExtractor extends TextExtractor {
  // pdf.js loads lazily, the first time a PDF is actually extracted.
  async extract(file: File): Promise<string> {
    const pdfjsLib = await loadPdfJs();

    const data = new Uint8Array(await file.arrayBuffer());
    const pdf = await pdfjsLib.getDocument({ data }).promise;

    const pages: string[] = [];
    for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber++) {
      const page = await pdf.getPage(pageNumber);
      const content = await page.getTextContent();
      const text = content.items
        .map((item) => ('str' in item ? (item as TextItem).str : ''))
        .join(' ');
      pages.push(text);
    }

    return pages.join('\n\n').trim();
  }
}
