CREATE TABLE airports (
    airport_id BIGSERIAL PRIMARY KEY,
    airport_name TEXT NOT NULL,
    country TEXT,
    state TEXT,
    city TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE airlines (
    airline_id BIGSERIAL PRIMARY KEY,
    airline_code VARCHAR(10) NOT NULL UNIQUE,
    name TEXT NOT NULL,
    country TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE flights (
    flight_id BIGSERIAL PRIMARY KEY,
    flight_number VARCHAR(20) NOT NULL,
    airline_id BIGINT NOT NULL REFERENCES airlines(airline_id) ON DELETE RESTRICT,
    departure_airport_id BIGINT NOT NULL REFERENCES airports(airport_id) ON DELETE RESTRICT,
    arrival_airport_id BIGINT NOT NULL REFERENCES airports(airport_id) ON DELETE RESTRICT,
    departing_gate VARCHAR(10),
    arriving_gate VARCHAR(10),
    scheduled_departure TIMESTAMPTZ,
    scheduled_arrival TIMESTAMPTZ,
    actual_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE passengers (
    passenger_id BIGSERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    gender VARCHAR(20),
    date_of_birth DATE,
    country_of_citizenship TEXT,
    country_of_residence TEXT,
    passport_number VARCHAR(64) UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    flight_id BIGINT NOT NULL REFERENCES flights(flight_id) ON DELETE RESTRICT,
    passenger_id BIGINT NOT NULL REFERENCES passengers(passenger_id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL,
    booking_platform VARCHAR(50),
    ticket_price NUMERIC(10,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE booking_changes (
    booking_change_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by VARCHAR(100), -- agent or system
    old_status VARCHAR(30),
    new_status VARCHAR(30),
    note TEXT
);

CREATE TABLE boarding_passes (
    boarding_pass_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE REFERENCES bookings(booking_id) ON DELETE CASCADE,
    seat VARCHAR(10),
    boarding_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE baggage (
    baggage_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    weight_kg NUMERIC(6,2) CHECK (weight_kg >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE baggage_checks (
    baggage_check_id BIGSERIAL PRIMARY KEY,
    baggage_id BIGINT NOT NULL REFERENCES baggage(baggage_id) ON DELETE CASCADE,
    booking_id BIGINT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    passenger_id BIGINT NOT NULL REFERENCES passengers(passenger_id) ON DELETE RESTRICT,
    check_results TEXT,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE security_checks (
    security_check_id BIGSERIAL PRIMARY KEY,
    passenger_id BIGINT NOT NULL REFERENCES passengers(passenger_id) ON DELETE CASCADE,
    check_results TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_airports') THEN
        CREATE TRIGGER trg_set_updated_at_airports BEFORE UPDATE ON airports FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_airlines') THEN
        CREATE TRIGGER trg_set_updated_at_airlines BEFORE UPDATE ON airlines FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_flights') THEN
        CREATE TRIGGER trg_set_updated_at_flights BEFORE UPDATE ON flights FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_passengers') THEN
        CREATE TRIGGER trg_set_updated_at_passengers BEFORE UPDATE ON passengers FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_bookings') THEN
        CREATE TRIGGER trg_set_updated_at_bookings BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_boarding_passes') THEN
        CREATE TRIGGER trg_set_updated_at_boarding_passes BEFORE UPDATE ON boarding_passes FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_baggage') THEN
        CREATE TRIGGER trg_set_updated_at_baggage BEFORE UPDATE ON baggage FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_baggage_checks') THEN
        CREATE TRIGGER trg_set_updated_at_baggage_checks BEFORE UPDATE ON baggage_checks FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_updated_at_security_checks') THEN
        CREATE TRIGGER trg_set_updated_at_security_checks BEFORE UPDATE ON security_checks FOR EACH ROW EXECUTE FUNCTION set_updated_at_column();
    END IF;
END;
$$ LANGUAGE plpgsql;

INSERT INTO airports (airport_name, country, state, city)
VALUES
('International Airport Almaty', 'Kazakhstan', 'ALmaty', 'Almaty'),
('International Airport Houston', 'USA', 'Texas', 'Houston');

INSERT INTO airlines (airline_code, name, country)
VALUES
('AA', 'AirAstana', 'Kazakhstan'),
('BB', 'AmericanAirlines', 'USA');

-- Example flight
INSERT INTO flights (flight_number, airline_id, departure_airport_id, arrival_airport_id, departing_gate, arriving_gate, scheduled_departure, scheduled_arrival)
VALUES ('AA100', 1, 1, 2, 'D5', 'A2', now() + interval '2 day', now() + interval '2 day 3 hours');

-- Passenger
INSERT INTO passengers (first_name, last_name, gender, date_of_birth, country_of_citizenship, country_of_residence, passport_number)
VALUES ('Bek', 'Yerlepes', 'Male', '2007-08-29', 'Kazakhstan', 'Kazakhstan', 'P1234567');

-- Booking (John -> AA100)
INSERT INTO bookings (flight_id, passenger_id, status, booking_platform, ticket_price)
VALUES (1, 1, 'booked', 'website', 250.00);

-- Boarding pass for booking 1
INSERT INTO boarding_passes (booking_id, seat, boarding_time)
VALUES (1, '43C', now() + interval '2 day');

-- Baggage for booking 1
INSERT INTO baggage (booking_id, weight_kg)
VALUES (1, 23.50);

-- Baggage check
INSERT INTO baggage_checks (baggage_id, booking_id, passenger_id, check_results)
VALUES (1, 1, 1, 'OK - scanned and cleared');

-- Security check for passenger 1
INSERT INTO security_checks (passenger_id, check_results)
VALUES (1, 'Cleared');

-- Booking change example
INSERT INTO booking_changes (booking_id, changed_by, old_status, new_status, note)
VALUES (1, 'agent1', 'booked', 'checked-in', 'Passenger checked in at counter');

-- 1) List bookings with passenger and flight info
-- SELECT b.booking_id, p.first_name, p.last_name, f.flight_number, a1.city AS departure_city, a2.city AS arrival_city, b.status
-- FROM bookings b
-- JOIN passengers p ON p.passenger_id = b.passenger_id
-- JOIN flights f ON f.flight_id = b.flight_id
-- JOIN airports a1 ON a1.airport_id = f.departure_airport_id
-- JOIN airports a2 ON a2.airport_id = f.arrival_airport_id;

-- 2) Get baggage status for a booking
-- SELECT bg.baggage_id, bg.weight_kg, bc.check_results, bc.checked_at
-- FROM baggage bg
-- LEFT JOIN baggage_checks bc ON bc.baggage_id = bg.baggage_id
-- WHERE bg.booking_id = 1;

-- 3) Show boarding pass + seat by passenger
-- SELECT p.first_name, p.last_name, bp.seat, bp.boarding_time
-- FROM passengers p
-- JOIN bookings b ON b.passenger_id = p.passenger_id
-- JOIN boarding_passes bp ON bp.booking_id = b.booking_id
-- WHERE p.passenger_id = 1;

