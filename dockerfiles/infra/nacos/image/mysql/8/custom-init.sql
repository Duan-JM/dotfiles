-- Update default nacos user password
-- This runs after nacos-mysql.sql during container init
UPDATE users SET password = '$2b$12$9PHxEqTnARoZOoN3QeE8neVR0ltMTzC5iNUIaNQCW.SsMMo7I4Wfi' WHERE username = 'nacos';
