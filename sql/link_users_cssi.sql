-- =============================================================================
-- SCRIPT DE REPARACIÓN: Creación de Usuarios (Versión Robusta)
-- =============================================================================

-- 1. Asegurar que pgcrypto esté en el esquema de extensiones
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

-- 2. Limpiar función previa
DROP FUNCTION IF EXISTS public.create_user_admin(text, text, text, text);

-- 3. Función definitiva con prefijos de esquema explícitos
CREATE OR REPLACE FUNCTION public.create_user_admin(
  email text,
  password text,
  full_name text,
  user_role text
)
RETURNS uuid AS $$
DECLARE
  new_user_id uuid;
BEGIN
  new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    id, 
    instance_id, 
    email, 
    encrypted_password, 
    email_confirmed_at, 
    raw_app_meta_data, 
    raw_user_meta_data, 
    created_at, 
    updated_at, 
    role, 
    aud,
    confirmation_token
  )
  VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    email,
    extensions.crypt(password, extensions.gen_salt('bf'::text)), -- Prefijo explícito y cast
    now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('full_name', full_name, 'role', user_role),
    now(),
    now(),
    'authenticated',
    'authenticated',
    ''
  );

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Forzar recarga de esquema
NOTIFY pgrst, 'reload schema';
