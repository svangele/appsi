-- =============================================================================
-- Unified Granular RLS Policies (Accesos)
-- =============================================================================

-- 1. PERFILES (profiles)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Ver perfiles: Admin o con permiso show_users
DROP POLICY IF EXISTS "Ver perfiles: permiso o admin" ON public.profiles;
CREATE POLICY "Ver perfiles: permiso o admin"
  ON public.profiles
  FOR SELECT
  USING (
    id = auth.uid() OR
    (permissions->>'show_users')::boolean = true OR
    role = 'admin'
  );

-- Modificar perfiles: Solo Admins
DROP POLICY IF EXISTS "Modificar perfiles: solo admins" ON public.profiles;
CREATE POLICY "Modificar perfiles: solo admins"
  ON public.profiles
  FOR UPDATE
  USING (role = 'admin')
  WITH CHECK (role = 'admin');

-- 2. INVENTARIO ISSI (issi_inventory)
ALTER TABLE public.issi_inventory ENABLE ROW LEVEL SECURITY;

-- Ver ISSI: permiso o admin
DROP POLICY IF EXISTS "Ver ISSI: permiso o admin" ON public.issi_inventory;
CREATE POLICY "Ver ISSI: permiso o admin"
  ON public.issi_inventory
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND ((permissions->>'show_issi')::boolean = true OR role = 'admin')
    )
  );

-- Modificar ISSI: permiso o admin (ajustable si se prefiere solo admin)
DROP POLICY IF EXISTS "Modificar ISSI: permiso o admin" ON public.issi_inventory;
CREATE POLICY "Modificar ISSI: permiso o admin"
  ON public.issi_inventory
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND ((permissions->>'show_issi')::boolean = true OR role = 'admin')
    )
  );

-- 3. COLABORADORES CSSI (cssi_contributors)
ALTER TABLE public.cssi_contributors ENABLE ROW LEVEL SECURITY;

-- Ver/Modificar CSSI: permiso o admin
DROP POLICY IF EXISTS "Acceso CSSI: permiso o admin" ON public.cssi_contributors;
CREATE POLICY "Acceso CSSI: permiso o admin"
  ON public.cssi_contributors
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND ((permissions->>'show_cssi')::boolean = true OR role = 'admin')
    )
  );

-- 4. LOGS DEL SISTEMA (system_logs)
ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;

-- Ver logs: permiso o admin
DROP POLICY IF EXISTS "Ver logs: permiso o admin" ON public.system_logs;
CREATE POLICY "Ver logs: permiso o admin"
  ON public.system_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
      AND ((permissions->>'show_logs')::boolean = true OR role = 'admin')
    )
  );

NOTIFY pgrst, 'reload schema';
