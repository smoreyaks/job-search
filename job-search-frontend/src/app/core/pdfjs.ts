// Loads pdf.js on first use (a lazy chunk, kept out of the initial bundle) and
// points it at its worker. Shared by the text extractor and the PDF viewer.
export async function loadPdfJs(): Promise<typeof import('pdfjs-dist')> {
  const pdfjsLib = await import('pdfjs-dist');
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('pdfjs-dist/build/pdf.worker.min.mjs', import.meta.url).toString();
  return pdfjsLib;
}
