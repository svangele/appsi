-- =============================================================================
-- SCRIPT DEFINITIVO: Creación de Usuarios y Sincronización de Perfiles
-- =============================================================================

-- 1. FUNCIÓN DE ADMINISTRACIÓN (Alta Fidelidad con GoTrue)
-- Esta función crea usuarios directamente en auth.users cumpliendo con todos
-- los requisitos de escaneo (no-nulls) y vinculación de identidad.
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

  -- A. Insertar en auth.users (Rellenando campos técnicos para evitar Scan Errors)
  INSERT INTO auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at, 
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
    role, aud, is_sso_user, is_anonymous,
    confirmation_token, recovery_token, email_change_token_new, 
    email_change_token_current, email_change, phone_change, 
    phone_change_token, reauthentication_token,
    email_change_confirm_status
  )
  VALUES (
    new_user_id, '00000000-0000-0000-0000-000000000000', LOWER(email),
    extensions.crypt(password, extensions.gen_salt('bf', 10)),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object(
      'sub', new_user_id,
      'email', LOWER(email),
      'full_name', full_name,
      'role', user_role,
      'email_verified', true,
      'phone_verified', false
    ),
    now(), now(), 'authenticated', 'authenticated', false, false,
    '', '', '', '', '', '', '', '', 0
  );

  -- B. Vincular identidad (Obligatorio para visibilidad en UI y Login)
  INSERT INTO auth.identities (
    id,               -- Identidad ID = User ID para máxima compatibilidad
    user_id, 
    identity_data, 
    provider, 
    provider_id,      -- Provider ID = User ID
    last_sign_in_at, 
    created_at, 
    updated_at
  )
  VALUES (
    new_user_id, 
    new_user_id,
    jsonb_build_object('sub', new_user_id, 'email', LOWER(email), 'email_verified', true),
    'email',
    new_user_id::text, 
    null, now(), now()
  );

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. DISPARADOR DE PERFILES (Seguro y Sincronizado)
-- Crea o actualiza el perfil público cuando nace un usuario en auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'full_name', 'Nuevo Usuario'), 
    (COALESCE(new.raw_user_meta_data->>'role', 'usuario'))::user_role
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. FUNCIÓN DE SEGURIDAD (No Recursiva)
-- Basada en JWT para evitar el error "Database error querying schema".
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. REFRESCAR SISTEMA
NOTIFY pgrst, 'reload schema';
