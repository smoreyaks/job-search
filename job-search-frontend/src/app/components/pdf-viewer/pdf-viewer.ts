import { Component, ElementRef, OnDestroy, effect, input, signal, viewChild } from '@angular/core';
import type { PDFDocumentProxy } from 'pdfjs-dist';
import { loadPdfJs } from '../../core/pdfjs';

// Draws every page of a PDF with pdf.js, fitted to the viewer's width and
// sharp on high-density screens. Redraws when given a different file.
@Component({
  selector: 'app-pdf-viewer',
  template: `
    @if (failed()) {
      <p class="message">This PDF couldn't be displayed. It may be damaged; the extracted text is still under Text.</p>
    }
    <div class="pages" #pages></div>
  `,
  styleUrl: './pdf-viewer.scss',
})
export class PdfViewer implements OnDestroy {
  readonly data = input.required<ArrayBuffer>();
  readonly failed = signal(false);
  private readonly pages = viewChild.required<ElementRef<HTMLDivElement>>('pages');
  private doc: PDFDocumentProxy | null = null;
  private renderId = 0;

  constructor() {
    effect(() => {
      void this.render(this.data());
    });
  }

  ngOnDestroy(): void {
    this.renderId++;
    void this.doc?.loadingTask.destroy();
  }

  private async render(data: ArrayBuffer): Promise<void> {
    const id = ++this.renderId;
    const container = this.pages().nativeElement;
    container.replaceChildren();
    this.failed.set(false);
    await this.doc?.loadingTask.destroy();
    this.doc = null;

    try {
      const pdfjsLib = await loadPdfJs();
      // pdf.js takes ownership of the buffer it's given, so hand it a copy and
      // keep the cached original usable for the next time this resume opens.
      const doc = await pdfjsLib.getDocument({ data: new Uint8Array(data.slice(0)) }).promise;
      if (id !== this.renderId) return void doc.loadingTask.destroy();
      this.doc = doc;

      const width = container.clientWidth || 300;
      const ratio = window.devicePixelRatio || 1;
      for (let n = 1; n <= doc.numPages; n++) {
        const page = await doc.getPage(n);
        if (id !== this.renderId) return;
        const viewport = page.getViewport({ scale: width / page.getViewport({ scale: 1 }).width });
        const canvas = document.createElement('canvas');
        canvas.width = Math.floor(viewport.width * ratio);
        canvas.height = Math.floor(viewport.height * ratio);
        canvas.style.width = `${Math.floor(viewport.width)}px`;
        canvas.setAttribute('aria-label', `Page ${n} of ${doc.numPages}`);
        container.append(canvas);
        await page.render({ canvas, viewport, transform: ratio === 1 ? undefined : [ratio, 0, 0, ratio, 0, 0] }).promise;
      }
    } catch {
      if (id === this.renderId) this.failed.set(true);
    }
  }
}
