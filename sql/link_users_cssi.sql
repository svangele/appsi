-- =============================================================================
-- Migration: Link Profiles with CSSI Contributors
-- Run this in Supabase SQL Editor
-- =============================================================================

-- 1. Add new columns to public.profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS cssi_id UUID REFERENCES public.cssi_contributors(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS numero_empleado TEXT;

-- 2. (Optional) Update existing profiles if they have matching names in CSSI
-- This is a best-effort sync for existing data
UPDATE public.profiles p
SET 
  cssi_id = c.id,
  numero_empleado = c.numero_empleado
FROM public.cssi_contributors c
WHERE 
  p.cssi_id IS NULL 
  AND (c.nombre || ' ' || c.paterno) ILIKE p.full_name;

COMMENT ON COLUMN public.profiles.cssi_id IS 'Referencia al colaborador en la tabla cssi_contributors';
COMMENT ON COLUMN public.profiles.numero_empleado IS 'Número de empleado sincronizado del sistema CSSI';
