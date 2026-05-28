import { apiRequest, asData, type JsonMap } from '@/lib/api';

export type CatalogOption = {
  uuid: string;
  name: string;
  fuel_type?: string;
  transmission?: string;
  body_type?: string;
};

function mapOptions(payload: unknown): CatalogOption[] {
  const rows = asData<JsonMap[]>(payload) ?? [];
  return rows
    .map((row) => ({
      uuid: String(row.uuid ?? ''),
      name: String(row.name ?? ''),
      fuel_type: row.fuel_type ? String(row.fuel_type) : undefined,
      transmission: row.transmission ? String(row.transmission) : undefined,
      body_type: row.body_type ? String(row.body_type) : undefined,
    }))
    .filter((row) => row.uuid && row.name);
}

export async function searchCatalogMakes(token: string, query = '', year?: number) {
  const payload = await apiRequest('/vehicle-catalog/makes', {
    token,
    query: {
      ...(query ? { q: query } : {}),
      ...(year ? { year } : {}),
      limit: 20,
    },
  });
  return mapOptions(payload);
}

export async function searchCatalogModels(
  token: string,
  makeUuid: string,
  query = '',
  year?: number,
) {
  const payload = await apiRequest('/vehicle-catalog/models', {
    token,
    query: {
      make_uuid: makeUuid,
      ...(query ? { q: query } : {}),
      ...(year ? { year } : {}),
      limit: 20,
    },
  });
  return mapOptions(payload);
}

export async function searchCatalogVariants(
  token: string,
  modelUuid: string,
  query = '',
  year?: number,
) {
  const payload = await apiRequest('/vehicle-catalog/variants', {
    token,
    query: {
      model_uuid: modelUuid,
      ...(query ? { q: query } : {}),
      ...(year ? { year } : {}),
      limit: 20,
    },
  });
  return mapOptions(payload);
}

export async function searchCatalogColors(
  token: string,
  query = '',
  variantUuid?: string,
) {
  const payload = await apiRequest('/vehicle-catalog/colors', {
    token,
    query: {
      ...(query ? { q: query } : {}),
      ...(variantUuid ? { variant_uuid: variantUuid } : {}),
      limit: 20,
    },
  });
  return mapOptions(payload);
}
