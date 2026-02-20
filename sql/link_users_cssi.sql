-- =============================================================================
-- SCRIPT CONSOLIDADO: Integridad de Base de Datos y Vinculación
-- Este script asegura que todas las tablas y columnas necesarias existan.
-- Ejecutar TODO este script en el SQL Editor de Supabase.
-- =============================================================================

-- 1. Asegurar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Asegurar que la tabla cssi_contributors exista con todas sus columnas
CREATE TABLE IF NOT EXISTS public.cssi_contributors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    nombre TEXT NOT NULL,
    paterno TEXT NOT NULL,
    materno TEXT,
    numero_empleado TEXT,
    foto_url TEXT,
    usuario_id UUID REFERENCES auth.users(id)
);

-- 3. Asegurar que perfiles tenga las columnas de vinculación
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS cssi_id UUID REFERENCES public.cssi_contributors(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS numero_empleado TEXT;

-- 4. Sincronización (Opcional - Best effort)
UPDATE public.profiles p
SET 
  cssi_id = c.id,
  numero_empleado = c.numero_empleado
FROM public.cssi_contributors c
WHERE 
  p.cssi_id IS NULL 
  AND (c.nombre || ' ' || c.paterno) ILIKE p.full_name;

-- 5. Comentarios de auditoría
COMMENT ON TABLE public.cssi_contributors IS 'Catálogo de colaboradores del sistema CSSI';
COMMENT ON COLUMN public.profiles.cssi_id IS 'ID del colaborador CSSI vinculado al perfil de usuario';
