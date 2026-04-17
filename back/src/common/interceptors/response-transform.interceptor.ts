import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ResponseEnvelope<T> {
  data: T;
  total?: number;
  page?: number;
  limit?: number;
}

@Injectable()
export class ResponseTransformInterceptor<T> implements NestInterceptor<T, ResponseEnvelope<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ResponseEnvelope<T>> {
    return next.handle().pipe(
      map((responseData) => {
        // If response already has a data property (paginated responses), pass through
        if (
          responseData &&
          typeof responseData === 'object' &&
          'data' in responseData &&
          ('total' in responseData || 'page' in responseData)
        ) {
          return responseData as ResponseEnvelope<T>;
        }

        // Wrap simple responses in the standard envelope
        return { data: responseData };
      }),
    );
  }
}
