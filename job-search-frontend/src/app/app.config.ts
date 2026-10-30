import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { TextExtractor } from './core/text-extractor';
import { PdfJsTextExtractor } from './core/pdf-js-text-extractor';
import { loadingInterceptor } from './core/http-interceptors';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withFetch(), withInterceptors([loadingInterceptor])),
    { provide: TextExtractor, useClass: PdfJsTextExtractor },
  ],
};
