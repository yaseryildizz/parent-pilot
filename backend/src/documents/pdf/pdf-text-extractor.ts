import * as pdfjs from "pdfjs-dist/legacy/build/pdf.mjs";
import type { TextItem } from "pdfjs-dist/types/src/display/api.js";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import type { ExtractedDocumentText } from "./extracted-document-text.js";
import { ProcessingError } from "../processing/document-processor.js";

const MIN_EXTRACTABLE_TEXT_CHARACTERS = 20;
const require = createRequire(import.meta.url);
const standardFontDataUrl = `${join(dirname(require.resolve("pdfjs-dist/package.json")), "standard_fonts")}/`;

export interface PDFTextExtractor {
  extract(bytes: Buffer): Promise<ExtractedDocumentText>;
}

export class PDFJSTextExtractor implements PDFTextExtractor {
  async extract(bytes: Buffer): Promise<ExtractedDocumentText> {
    try {
      pdfjs.VerbosityLevel.ERRORS;
      const loadingTask = pdfjs.getDocument({
        data: new Uint8Array(bytes),
        disableFontFace: true,
        isEvalSupported: false,
        standardFontDataUrl,
        useWorkerFetch: false
      });
      const pdf = await loadingTask.promise;
      try {
        const pages = [];
        for (let index = 1; index <= pdf.numPages; index += 1) {
          const page = await pdf.getPage(index);
          const content = await page.getTextContent();
          const text = content.items.map(textFromItem).filter(Boolean).join(" ").trim();
          pages.push({ pageNumber: index, text });
        }
        const fullText = pages.map((page) => `[[page ${page.pageNumber}]]\n${page.text}`).join("\n\n");
        if (fullText.replace(/\s+/g, "").length < MIN_EXTRACTABLE_TEXT_CHARACTERS) {
          throw new ProcessingError(
            "noExtractableText",
            "PDF contains too little extractable text. OCR is required for scanned/image PDFs."
          );
        }
        return { pages, fullText };
      } finally {
        await pdf.destroy();
      }
    } catch (error) {
      if (error instanceof ProcessingError) throw error;
      throw new ProcessingError("pdfExtractionFailed", "PDF text extraction failed.", { cause: error });
    }
  }
}

function textFromItem(item: unknown): string {
  if (isTextItem(item)) return item.str;
  return "";
}

function isTextItem(item: unknown): item is TextItem {
  return typeof item === "object" && item !== null && "str" in item && typeof item.str === "string";
}
