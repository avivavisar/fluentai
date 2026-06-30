import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from '../config/env';

// Private bucket for user media (audio recordings, assets). Created on boot if missing.
export const MEDIA_BUCKET = 'media';

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private readonly client: SupabaseClient | null =
    env.SUPABASE_URL && env.SUPABASE_SERVICE_ROLE_KEY
      ? createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
          auth: { persistSession: false, autoRefreshToken: false },
        })
      : null;

  isConfigured(): boolean {
    return this.client !== null;
  }

  async onModuleInit(): Promise<void> {
    if (!this.client) {
      this.logger.warn('Storage not configured (SUPABASE_URL / SERVICE_ROLE_KEY missing).');
      return;
    }
    try {
      await this.ensureBucket(MEDIA_BUCKET);
    } catch (err) {
      this.logger.warn(`ensureBucket(${MEDIA_BUCKET}) failed: ${(err as Error).message}`);
    }
  }

  async ensureBucket(name: string, isPublic = false): Promise<void> {
    const client = this.requireClient();
    const { data } = await client.storage.getBucket(name);
    if (!data) {
      const { error } = await client.storage.createBucket(name, { public: isPublic });
      if (error && !/already exists/i.test(error.message)) throw error;
    }
  }

  async upload(
    path: string,
    body: Buffer | Uint8Array | string,
    contentType: string,
    bucket: string = MEDIA_BUCKET,
  ): Promise<{ bucket: string; path: string }> {
    const client = this.requireClient();
    const { error } = await client.storage
      .from(bucket)
      .upload(path, body, { contentType, upsert: true });
    if (error) throw error;
    return { bucket, path };
  }

  async signedUrl(
    path: string,
    expiresInSeconds = 3600,
    bucket: string = MEDIA_BUCKET,
  ): Promise<string> {
    const client = this.requireClient();
    const { data, error } = await client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
    if (error || !data) throw error ?? new Error('Failed to create signed URL');
    return data.signedUrl;
  }

  private requireClient(): SupabaseClient {
    if (!this.client) throw new Error('Storage is not configured.');
    return this.client;
  }
}
