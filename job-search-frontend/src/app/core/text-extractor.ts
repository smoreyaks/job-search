// Port (Angular-side) for pulling plain text out of a PDF file. The component
// depends on this abstraction, so the pdf.js implementation can be swapped (or
// faked in tests) via DI.
export abstract class TextExtractor {
  abstract extract(file: File): Promise<string>;
}
