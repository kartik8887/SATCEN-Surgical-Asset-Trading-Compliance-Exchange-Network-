-- =====================================================
-- SATCEN Hospital Management System - Final Database Schema
-- Complete MySQL Database with OTP Verification
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS satcen_hospital DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE satcen_hospital;

-- =====================================================
-- 1. USERS TABLE (Authentication)
-- =====================================================
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_sign_in_at TIMESTAMP NULL,
    role ENUM('hospital_admin', 'super_admin', 'hospital_staff') DEFAULT 'hospital_admin',
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_users_email (email),
    INDEX idx_users_role (role),
    INDEX idx_users_active (is_active)
);

-- =====================================================
-- 2. EMAIL OTP VERIFICATION TABLE
-- =====================================================
CREATE TABLE email_otps (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    purpose ENUM('email_verification', 'password_reset', 'login_verification') NOT NULL,
    user_id VARCHAR(36) NULL,
    is_used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_email_otps_email (email),
    INDEX idx_email_otps_code (otp_code),
    INDEX idx_email_otps_expires (expires_at),
    INDEX idx_email_otps_purpose (purpose)
);

-- =====================================================
-- 3. USER PROFILES TABLE
-- =====================================================
CREATE TABLE user_profiles (
    id VARCHAR(36) PRIMARY KEY,
    hospital_id VARCHAR(36) NULL,
    role ENUM('hospital_admin', 'super_admin', 'hospital_staff') DEFAULT 'hospital_admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_profiles_hospital_id (hospital_id),
    INDEX idx_user_profiles_role (role)
);

-- =====================================================
-- 4. HOSPITALS TABLE
-- =====================================================
CREATE TABLE hospitals (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    website VARCHAR(255) NULL,
    established_year INT NULL,
    bed_capacity INT NULL,
    specializations JSON NULL,
    certifications JSON NULL,
    verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    verification_documents JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_hospitals_user_id (user_id),
    INDEX idx_hospitals_verification_status (verification_status),
    INDEX idx_hospitals_city (city),
    INDEX idx_hospitals_state (state)
);

-- =====================================================
-- 5. HOSPITAL STAFF TABLE
-- =====================================================
CREATE TABLE hospital_staff (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    hospital_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    role ENUM('admin', 'technician', 'manager', 'viewer') DEFAULT 'viewer',
    department VARCHAR(100) NULL,
    hire_date DATE NULL,
    temp_password VARCHAR(255) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_hospital_staff_hospital_id (hospital_id),
    INDEX idx_hospital_staff_user_id (user_id),
    INDEX idx_hospital_staff_email (email),
    INDEX idx_hospital_staff_active (is_active)
);

-- =====================================================
-- 6. ASSETS TABLE
-- =====================================================
CREATE TABLE assets (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    hospital_id VARCHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100) NULL,
    model VARCHAR(100) NULL,
    serial_number VARCHAR(100) NULL,
    description TEXT NULL,
    condition_status ENUM('new', 'excellent', 'good', 'fair', 'poor') DEFAULT 'good',
    listing_type ENUM('rent', 'sale', 'both') DEFAULT 'rent',
    rent_price_per_day DECIMAL(10,2) NULL,
    sale_price DECIMAL(12,2) NULL,
    location VARCHAR(255) NULL,
    availability_status ENUM('available', 'rented', 'sold', 'maintenance', 'reserved') DEFAULT 'available',
    images JSON NULL,
    specifications JSON NULL,
    compliance_certificates JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    INDEX idx_assets_hospital_id (hospital_id),
    INDEX idx_assets_category (category),
    INDEX idx_assets_status (availability_status),
    INDEX idx_assets_listing_type (listing_type),
    INDEX idx_assets_location (location)
);

-- =====================================================
-- 7. STAFF REQUESTS TABLE
-- =====================================================
CREATE TABLE staff_requests (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    staff_id VARCHAR(36) NOT NULL,
    asset_id VARCHAR(36) NOT NULL,
    request_type ENUM('rent', 'purchase') NOT NULL,
    duration_days INT NULL,
    requested_start_date DATE NULL,
    requested_end_date DATE NULL,
    status ENUM('pending', 'approved', 'rejected', 'completed', 'cancelled') DEFAULT 'pending',
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    justification TEXT NULL,
    admin_notes TEXT NULL,
    approved_by VARCHAR(36) NULL,
    approved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES hospital_staff(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_staff_requests_staff_id (staff_id),
    INDEX idx_staff_requests_asset_id (asset_id),
    INDEX idx_staff_requests_status (status),
    INDEX idx_staff_requests_priority (priority)
);

-- =====================================================
-- 8. TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE transactions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    request_id VARCHAR(36) NULL,
    renter_hospital_id VARCHAR(36) NOT NULL,
    owner_hospital_id VARCHAR(36) NOT NULL,
    asset_id VARCHAR(36) NOT NULL,
    transaction_type ENUM('rent', 'sale') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    duration_days INT NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    status ENUM('pending', 'active', 'completed', 'cancelled', 'overdue') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'partial', 'refunded') DEFAULT 'pending',
    payment_method VARCHAR(50) NULL,
    transaction_fee DECIMAL(10,2) NULL,
    security_deposit DECIMAL(10,2) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES staff_requests(id) ON DELETE SET NULL,
    FOREIGN KEY (renter_hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    INDEX idx_transactions_renter (renter_hospital_id),
    INDEX idx_transactions_owner (owner_hospital_id),
    INDEX idx_transactions_asset (asset_id),
    INDEX idx_transactions_status (status),
    INDEX idx_transactions_payment_status (payment_status)
);

-- =====================================================
-- 9. ASSET VIEWS TABLE (Analytics)
-- =====================================================
CREATE TABLE asset_views (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    asset_id VARCHAR(36) NOT NULL,
    staff_id VARCHAR(36) NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_duration_seconds INT NULL,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES hospital_staff(id) ON DELETE CASCADE,
    INDEX idx_asset_views_asset_id (asset_id),
    INDEX idx_asset_views_staff_id (staff_id),
    INDEX idx_asset_views_viewed_at (viewed_at)
);

-- =====================================================
-- 10. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    hospital_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NULL,
    type ENUM('system', 'request', 'transaction', 'compliance', 'payment') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action_url VARCHAR(500) NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_notifications_hospital_id (hospital_id),
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_type (type),
    INDEX idx_notifications_read (is_read),
    INDEX idx_notifications_created_at (created_at)
);

-- =====================================================
-- 11. STAFF NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE staff_notifications (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    staff_id VARCHAR(36) NOT NULL,
    type ENUM('request_update', 'asset_available', 'system', 'reminder') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action_url VARCHAR(500) NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (staff_id) REFERENCES hospital_staff(id) ON DELETE CASCADE,
    INDEX idx_staff_notifications_staff_id (staff_id),
    INDEX idx_staff_notifications_type (type),
    INDEX idx_staff_notifications_read (is_read),
    INDEX idx_staff_notifications_created_at (created_at)
);

-- =====================================================
-- 12. ACTIVITY LOGS TABLE
-- =====================================================
CREATE TABLE activity_logs (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    hospital_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    action ENUM('create', 'update', 'delete', 'approve', 'reject', 'request', 'complete') NOT NULL,
    entity_type ENUM('asset', 'request', 'transaction', 'staff', 'hospital') NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    details JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_activity_logs_hospital_id (hospital_id),
    INDEX idx_activity_logs_user_id (user_id),
    INDEX idx_activity_logs_entity (entity_type, entity_id),
    INDEX idx_activity_logs_created_at (created_at)
);

-- =====================================================
-- 13. USER SESSIONS TABLE
-- =====================================================
CREATE TABLE user_sessions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id VARCHAR(36) NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_sessions_user_id (user_id),
    INDEX idx_user_sessions_token (session_token),
    INDEX idx_user_sessions_expires_at (expires_at)
);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- =====================================================
DELIMITER //

CREATE TRIGGER users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER hospitals_updated_at 
    BEFORE UPDATE ON hospitals 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER hospital_staff_updated_at 
    BEFORE UPDATE ON hospital_staff 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER assets_updated_at 
    BEFORE UPDATE ON assets 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER staff_requests_updated_at 
    BEFORE UPDATE ON staff_requests 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER transactions_updated_at 
    BEFORE UPDATE ON transactions 
    FOR EACH ROW 
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

DELIMITER ;

-- =====================================================
-- CLEANUP PROCEDURES
-- =====================================================

-- Procedure to clean expired OTPs (run periodically)
DELIMITER //
CREATE PROCEDURE CleanExpiredOTPs()
BEGIN
    DELETE FROM email_otps WHERE expires_at < NOW();
END//

-- Procedure to clean old sessions (run periodically)
CREATE PROCEDURE CleanExpiredSessions()
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW();
END//

-- Procedure to clean old activity logs (keep last 6 months)
CREATE PROCEDURE CleanOldActivityLogs()
BEGIN
    DELETE FROM activity_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);
END//

DELIMITER ;

-- =====================================================
-- SAMPLE DATA (Optional - Remove if not needed)
-- =====================================================

-- Create super admin user 
-- Email: admin@satcen.com
-- Password: SuperAdmin123!
INSERT INTO users (id, email, password_hash, role, email_verified) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'admin@satcen.com', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'super_admin', TRUE);

INSERT INTO user_profiles (id, role) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'super_admin');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all tables are created
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    CREATE_TIME
FROM 
    INFORMATION_SCHEMA.TABLES 
WHERE 
    TABLE_SCHEMA = 'satcen_hospital'
ORDER BY 
    TABLE_NAME;

-- Show foreign key relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE 
    TABLE_SCHEMA = 'satcen_hospital' 
    AND REFERENCED_TABLE_NAME IS NOT NULL;

SELECT 'Database schema created successfully with OTP verification!' as message;