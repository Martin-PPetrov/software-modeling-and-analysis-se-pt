CREATE DATABASE bookingdb;

CREATE TABLE users (
	user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	full_name VARCHAR(100) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	password_hash VARCHAR(255) NOT NULL,
	phone VARCHAR(20),
	"role" VARCHAR(20) CHECK ("role" IN ('Guest', 'Host')),
	date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (full_name, email, password_hash, phone, "role")
VALUES 
('Ivaylo Ivanov', 'ivaylo@example.com', 'hash123', '+359888111222', 'Host'),
('Maria Ovcharova', 'maria@example.com', 'hash456', '+359888333444', 'Host'),
('Elena Taneva', 'elena@example.com', 'hash789', '+359888777333', 'Guest');

CREATE TABLE properties (
	property_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	host_id INT NOT NULL,
	title VARCHAR(150) NOT NULL,
	description TEXT,
	address VARCHAR(255),
	city VARCHAR(100),
	country VARCHAR(100),
	price_per_night DECIMAL(10,2) NOT NULL,
	max_guests INT,
	date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_properties_users FOREIGN KEY (host_id) REFERENCES users(user_id)
);

INSERT INTO properties (host_id, title, description, address, 
city, country, price_per_night, max_guests)
VALUES 
(1, 'Sunny Apartment', 'A cozy apartment near the beach', '12 Sea Street',
'Varna', 'Bulgaria', 85.00, 3),
(1, 'Mountain Cabin', 'Quiet cabin with a fireplace', '88 Forest Road',
'Bansko', 'Bulgaria', 120.00, 5),
(2, 'City Studio', 'A modern studio in the city center', '5 Kings Road',
'Sofia', 'Bulgaria', 95.00, 2);

CREATE TABLE amenities (
	amenity_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	amenity_name VARCHAR(100) NOT NULL 
);

INSERT INTO amenities (amenity_name)
VALUES 
('WiFi'),
('Parking'),
('Air Conditioning'),
('Swimming Pool'),
('Breakfast Included'),
('TV'),
('Heating');

CREATE TABLE properties_amenities (
	property_id INT NOT NULL,
	amenity_id INT NOT NULL,
	PRIMARY KEY (property_id, amenity_id),
	CONSTRAINT fk_properties_amenities_properties
		FOREIGN KEY (property_id) REFERENCES properties(property_id),
	CONSTRAINT fk_properties_amenities_amenities
		FOREIGN KEY (amenity_id) REFERENCES amenities(amenity_id)
);

INSERT INTO properties_amenities (property_id, amenity_id)
VALUES 
(1, 1), (1, 2), (1, 3), -- Sunny Apartment
(2, 1), (2, 2), (2, 7), -- Mountain Cabin
(3, 1), (3, 3), (3, 6); -- City Studio

CREATE TABLE bookings (
	booking_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	property_id INT NOT NULL,
	user_id INT NOT NULL,
	check_in_date DATE NOT NULL,
	check_out_date DATE NOT NULL,
	total_price DECIMAL(10,2) NOT NULL,
	status VARCHAR(20) CHECK (status IN ('Pending', 'Confirmed', 'Cancelled')) DEFAULT 'Pending',
	booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_bookings_properties
		FOREIGN KEY (property_id) REFERENCES properties(property_id),
	CONSTRAINT fk_bookings_users
		FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO bookings (property_id, user_id, check_in_date, check_out_date, 
total_price, status)
VALUES 
(1, 3, '2025-07-01', '2025-07-05', 340.00, 'Confirmed'),
(2, 1, '2025-08-10', '2025-08-15', 600.00, 'Pending'),
(3, 3, '2025-09-01', '2025-09-03', 190.00, 'Confirmed');

CREATE TABLE reviews (
	review_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	booking_id INT NOT NULL,
	rating INT CHECK (rating BETWEEN 1 AND 5),
	"comment" TEXT,
	review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_reviews_bookings
		FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

INSERT INTO reviews (booking_id, rating, "comment")
VALUES 
(1, 5, 'Amazing stay, great host and location!'),
(3, 4, 'Nice studio, a bit noisy but clean.');

CREATE TABLE payments (
	payment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	booking_id INT NOT NULL,
	amount DECIMAL(10,2) NOT NULL,
	payment_method VARCHAR(50),
	payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CONSTRAINT fk_payments_bookings
		FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

INSERT INTO payments (booking_id, amount, payment_method)
VALUES 
(1, 340.00, 'Credit Card'),
(2, 600.00, 'PayPal'),
(3, 190.00, 'Debit Card');

CREATE TABLE property_images (
	image_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	property_id INT NOT NULL,
	image_url VARCHAR(255),
	caption VARCHAR(255),
	CONSTRAINT fk_property_images_properties
		FOREIGN KEY (property_id) REFERENCES properties(property_id)
);

INSERT INTO property_images (property_id, image_url, caption)
VALUES 
(1, 'https://example.com/images/apt1_main.jpg', 'Living room view'),
(1, 'https://example.com/images/apt1_bedroom.jpg', 'Cozy bedroom'),
(2, 'https://example.com/images/cabin_main.jpg', 'Cabin in the woods'),
(3, 'https://example.com/images/studio_main.jpg', 'Modern city studio');

---------------------------------------------
CREATE OR REPLACE PROCEDURE create_booking (
	parameter_property_id INT,
	parameter_guest_id INT,
	parameter_check_in DATE,
	parameter_check_out DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
	variable_price_per_night DECIMAL(10,2);
	variable_total DECIMAL(10,2);
	variable_days INT;
BEGIN
	SELECT price_per_night INTO variable_price_per_night
	FROM properties
	WHERE property_id = parameter_property_id;

	variable_days := (parameter_check_out - parameter_check_in);
	variable_total := variable_price_per_night * variable_days;

	INSERT INTO bookings (property_id, user_id, check_in_date,
	check_out_date, total_price, status)
	VALUES (parameter_property_id, parameter_guest_id, parameter_check_in,
	parameter_check_out, variable_total, 'Pending');

	RAISE NOTICE 'Booking created: total price = %', variable_total;
END;
$$;

CALL create_booking(1, 3, '2025-12-01', '2025-12-04');

SELECT * FROM bookings WHERE user_id = 3 ORDER BY booking_id DESC;

CREATE OR REPLACE PROCEDURE update_booking_status (
	parameter_booking_id INT,
	parameter_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE bookings
	SET status = parameter_new_status
	WHERE booking_id = parameter_booking_id;

	RAISE NOTICE 'Booking % status updated to %', parameter_booking_id, parameter_new_status;
END;
$$;

CALL update_booking_status(4, 'Confirmed');

SELECT booking_id, status FROM bookings WHERE booking_id = 4;

CREATE OR REPLACE FUNCTION get_average_rating(parameter_property_id INT)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
AS $$
DECLARE
	variable_average DECIMAL(3,2);
BEGIN
	SELECT AVG(r.rating)
	INTO variable_average
	FROM reviews AS r
	JOIN bookings AS b ON r.booking_id = b.booking_id
	WHERE b.property_id = parameter_property_id;

	RETURN COALESCE(variable_average, 0);
END;
$$;

SELECT get_average_rating(1) AS average_rating;

CREATE OR REPLACE FUNCTION get_host_name_by_property(parameter_property_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
	variable_name VARCHAR;
BEGIN
	SELECT u.full_name INTO variable_name
	FROM users AS u
	JOIN properties AS p ON u.user_id = p.host_id
	WHERE p.property_id = parameter_property_id;

	RETURN variable_name;
END;
$$;

SELECT get_host_name_by_property(1) AS host_name;

CREATE OR REPLACE FUNCTION auto_create_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	variable_payment_method VARCHAR(50);
BEGIN
	IF OLD.status = 'Pending' AND NEW.status = 'Confirmed' THEN

		IF NEW.status = 'Confirmed' THEN

			IF NOT EXISTS (SELECT 1 FROM payments WHERE booking_id = NEW.booking_id) THEN

				BEGIN
					SELECT payment_method INTO variable_payment_method
					FROM bookings
					WHERE booking_id = NEW.booking_id;
				EXCEPTION
					WHEN undefined_column THEN
 						variable_payment_method := 'Unknown';
				END;

				INSERT INTO payments (booking_id, amount, payment_method)
				VALUES (NEW.booking_id, NEW.total_price, COALESCE(variable_payment_method, 'Unknown'));
		
				RAISE NOTICE 'New payment created for booking_id: % (method: %)', NEW.booking_id, variable_payment_method;
			
			ELSE
				
				RAISE NOTICE 'Payment already exists for booking_id: % - skipping insert.', NEW.booking_id;
			
			END IF;

		END IF;

	END IF;

	IF OLD.status = 'Confirmed' THEN

		RAISE NOTICE 'Status is already confirmed for booking_id: %', NEW.booking_id;
	
	END IF;

	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_auto_payment
AFTER UPDATE OF status ON bookings
FOR EACH ROW
WHEN (NEW.status = 'Confirmed')
EXECUTE FUNCTION auto_create_payment();

CALL update_booking_status(3, 'Confirmed');

SELECT * FROM payments WHERE booking_id = 3;

ALTER TABLE bookings ADD COLUMN payment_method VARCHAR(50);

UPDATE bookings
SET status = 'Confirmed', payment_method = 'Bank Transfer'
WHERE booking_id = 3;

SELECT * FROM payments WHERE booking_id = 3;

ALTER TABLE bookings DROP COLUMN payment_method;

CREATE OR REPLACE FUNCTION set_review_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	IF NEW.review_date IS NULL THEN
		NEW.review_date := CURRENT_TIMESTAMP;
	END IF;

	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_review_date
BEFORE INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION set_review_date();

INSERT INTO reviews (booking_id, rating, "comment")
VALUES (1, 5, 'Excellent host and clean property');

SELECT * FROM reviews WHERE booking_id = 1;

CREATE OR REPLACE FUNCTION validate_review_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	booking_status VARCHAR(20);
BEGIN
	SELECT status INTO booking_status
	FROM bookings
	WHERE booking_id = NEW.booking_id;

	IF booking_status <> 'Confirmed' THEN
		RAISE EXCEPTION 'Cannot add review: booking is not confirmed.';
	END IF;

	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_validate_review_booking
BEFORE INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION validate_review_booking();

INSERT INTO reviews (booking_id, rating, "comment")
VALUES (3, 5, 'Excellent host and clean property');

SELECT * FROM reviews WHERE booking_id = 3;


----------------------------------------------------------

CREATE OR REPLACE VIEW bookings_by_month AS
SELECT
	DATE_TRUNC('month', booking_date)::date AS month_start,
	EXTRACT(YEAR FROM booking_date)::int AS "year",
	EXTRACT(MONTH FROM booking_date)::int AS "month",
	COUNT(booking_id) AS bookings_count
FROM bookings
WHERE booking_date IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1;

CREATE OR REPLACE VIEW revenue_by_city AS
SELECT
	pr.city,
	SUM(b.total_price)::numeric(12,2) AS total_revenue
FROM bookings AS b
JOIN properties AS pr ON b.property_id = pr.property_id
GROUP BY pr.city
ORDER BY total_revenue DESC;
	
CREATE OR REPLACE VIEW average_rating_per_property AS
SELECT
	pr.property_id,
	pr.title AS property_name,
	ROUND(AVG(r.rating)::NUMERIC, 2) AS average_rating,
	COUNT(r.review_id) AS reviews_count
FROM reviews AS r
JOIN bookings AS b ON r.booking_id = b.booking_id
JOIN properties AS pr ON b.property_id = pr.property_id
GROUP BY pr.property_id, pr.title
ORDER BY average_rating DESC;

CREATE OR REPLACE VIEW bookings_per_host AS 
SELECT 
	u.user_id AS host_id,
	u.full_name AS host_name,
	COUNT(b.booking_id) AS bookings_count
FROM bookings AS b
JOIN properties AS pr ON b.property_id = pr.property_id
JOIN users AS u ON pr.host_id = u.user_id
GROUP BY u.user_id, u.full_name
ORDER BY bookings_count DESC;













