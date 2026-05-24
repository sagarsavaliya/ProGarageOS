import { API_BASE_URL, ApiError } from '@/lib/api';

export async function uploadMultipart(
  path: string,
  token: string,
  formData: FormData,
): Promise<unknown> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  const text = await response.text();
  const payload = text ? JSON.parse(text) : {};

  if (!response.ok) {
    const nestedError = (payload as { error?: { message?: string } }).error;
    throw new ApiError(
      nestedError?.message ?? (payload as { message?: string }).message ?? 'Upload failed',
      response.status,
    );
  }

  return payload;
}
