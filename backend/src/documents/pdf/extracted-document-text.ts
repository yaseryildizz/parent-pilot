export type ExtractedDocumentPage = {
  pageNumber: number;
  text: string;
};

export type ExtractedDocumentText = {
  pages: ExtractedDocumentPage[];
  fullText: string;
};
