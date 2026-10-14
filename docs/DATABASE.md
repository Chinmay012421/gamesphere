# Database notes

The initial PostgreSQL schema is in `supabase/migrations/001_initial_schema.sql`.

1. Create a Supabase project.
2. Run the migration in the Supabase SQL Editor or with the Supabase CLI.
3. Configure Auth providers and allowed redirect URLs.
4. Configure a private storage bucket for uploads; add policies before enabling uploads.
5. Review every RLS policy before real users join. In particular, match outcomes and tournament entry capacity should be validated transactionally on the server.

This repository includes the database foundation but not the complete authentication or CRUD integration yet.
