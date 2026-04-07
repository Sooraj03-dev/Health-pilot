-- RLS Policy for storage.objects
-- Ensures only doctors with an active assignment to the patient can read files
-- Table: storage.objects
-- Path structure: medical-docs/{patient_id}/filename.ext

-- First, ensure RLS is enabled for the storage.objects table if not already done:
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Note: Doctor authentication must be properly established where auth.uid() reflects the doctor's user ID.
-- The assigned_patients table should have (doctor_id, patient_id) columns.

CREATE POLICY "Doctors can view assigned patients records"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'medical-docs'
  AND (
    auth.uid() IN (
      SELECT ap.doctor_id 
      FROM public.assigned_patients ap 
      WHERE ap.patient_id::text = (string_to_array(storage.objects.name, '/'))[1]
    )
  )
);
