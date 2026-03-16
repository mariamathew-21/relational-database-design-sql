-- TABLE: Country
------------------------------
CREATE TABLE Country (
    Country_ID INTEGER PRIMARY KEY,
    Country_Name TEXT NOT NULL UNIQUE
);

-- TABLE: Manufacturer
-------------------------------
CREATE TABLE Manufacturer (
    Manufacturer_ID INTEGER PRIMARY KEY,
    Manufacturer_Name TEXT NOT NULL
);


-- TABLE: Vaccine
------------------------------

CREATE TABLE Vaccine (
    Vaccine_ID INTEGER PRIMARY KEY,
    Vaccine_Name TEXT NOT NULL,
    Manufacturer_ID INTEGER,
    FOREIGN KEY (Manufacturer_ID) REFERENCES Manufacturer(Manufacturer_ID)
);

-- TABLE: Vaccination_Record
---------------------------

CREATE TABLE Vaccination_Record (
    Record_ID INTEGER PRIMARY KEY,
    Date TEXT NOT NULL,
    Total_Vaccinations INTEGER,
    Daily_Vaccinations INTEGER,
    Country_ID INTEGER,
    Vaccine_ID INTEGER,
    FOREIGN KEY (Country_ID) REFERENCES Country(Country_ID),
    FOREIGN KEY (Vaccine_ID) REFERENCES Vaccine(Vaccine_ID)
);

-- TABLE: Data_Source
---------------------------------

CREATE TABLE Data_Source (
    Source_ID INTEGER PRIMARY KEY,
    Source_Name TEXT NOT NULL,
    Source_URL TEXT NOT NULL,
    Country_ID INTEGER,
    FOREIGN KEY (Country_ID) REFERENCES Country(Country_ID)
);


-- TABLE: Vaccination_AgeGroup
-------------------------------------

CREATE TABLE Vaccination_AgeGroup (
    Age_GroupID INTEGER PRIMARY KEY,
    AgeGroup TEXT NOT NULL,
    Country_ID INTEGER,
    Vaccine_ID INTEGER,
    FOREIGN KEY (Country_ID) REFERENCES Country(Country_ID),
    FOREIGN KEY (Vaccine_ID) REFERENCES Vaccine(Vaccine_ID)
);

-- TABLE: US_State_Vaccination
--------------------------------------------

CREATE TABLE US_State_Vaccination (
    State_ID INTEGER PRIMARY KEY,
    State_Name TEXT NOT NULL,
    Date TEXT NOT NULL,
    Total_Vaccinations INTEGER,
    People_Vaccinated INTEGER,
    People_Fully_Vaccinated INTEGER,
    Country_ID INTEGER,
    FOREIGN KEY (Country_ID) REFERENCES Country(Country_ID)
);

