from ehrql import INTERVAL, create_measures, case, when, years, months, weeks

from ehrql.tables.tpp import (
    clinical_events,
    patients,
    practice_registrations,
    addresses,
    appointments,
)

from codelists import (
    f2f_consultation,
    virtual_consultation,
    ethnicity_codelist,
)

# Instantiate dataset
measures = create_measures()
measures.configure_dummy_data(population_size=5000)

# Extract clinical events that fall between our start and end date
# for further use in variable definitions below
selected_events = clinical_events.where(
    clinical_events.date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
)

# Virtual consultations identified through clinical codes
# Check if a patient has a clinical code in the time period defined
# above (selected_events) that are in the virtual_consultation codelist
has_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).exists_for_patient()

# Count number of virtual_consultation that a patient had
# in the time period defined above (selected_events)
count_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).count_for_patient()

last_virtual_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(virtual_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# f2f (face to face) consultations identified through clinical codes
has_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).exists_for_patient()

# Count number of f2f that a patient had
count_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).count_for_patient()

last_f2f_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(f2f_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# Appointments identified through the appointments table
# Get all appointments with seen date
appointments_seen = appointments.where(
    appointments.status.is_in(
        [
            "Arrived",
            "In Progress",
            "Finished",
            "Visit",
            "Waiting",
            "Patient Walked Out",
        ]
    )
).where(appointments.seen_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date))

# Specify if a patient had (True/False) a finished appointments in the time period
has_appointment = appointments_seen.exists_for_patient()

# Demographic variables and other patient characteristics
# Define variable that checks if a patients is registered at the start date
has_registration = practice_registrations.for_patient_on(
    INTERVAL.start_date
).exists_for_patient()

age = patients.age_on(INTERVAL.start_date)
age_greater_equal_65 = age >= 65
age_band = case(
    when((age >= 18) & (age < 50)).then("age_18_49"),
    when((age >= 50) & (age < 65)).then("age_50_64"),
    when((age >= 65) & (age < 75)).then("age_65_74"),
    when((age >= 75) & (age < 85)).then("age_75_84"),
    when((age >= 85)).then("age_greater_equal_85"),
    otherwise="Missing",
)

# Define patient sex and date of death
sex = patients.sex
dod = patients.date_of_death

# Define patient address: MSOA, rural-urban and IMD rank, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5"),
    otherwise="Missing",
)

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before(INTERVAL.end_date))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

latest_ethnicity = latest_ethnicity_code.to_category(ethnicity_codelist)

# Convert ethnicity group numbers into strings
ethnicity = case(
    when(latest_ethnicity == "1").then("White"),
    when(latest_ethnicity == "2").then("Mixed"),
    when(latest_ethnicity == "3").then("Asian or Asian British"),
    when(latest_ethnicity == "4").then("Black or Black British"),
    when(latest_ethnicity == "5").then("Chinese or Other Ethnic Groups"),
    otherwise="missing",
)

# Count number of seen appointments in the time period
count_appointment = appointments_seen.where(
    has_registration & (age >= 18)
).count_for_patient() 

# Specify description and start dates for measures
measures_start_dates = {
    "pre2019": "2019-03-23",
    "during2020": "2020-03-23",
    "during2021": "2021-03-23",
}

# Iterate through the start dates in measures_start_dates and
# calculate measures for each age sex/ethnicity/imd pair
for time_description, start_date in measures_start_dates.items():
    measures.define_measure(
        name=f"count_virtual_{time_description}_monthly_age",
        numerator=count_virtual_consultation,
        denominator=count_appointment,
        group_by={
            "age_band": age_band,
            "sex": sex,
            "ethnicity": ethnicity,
            "imd_quintile": imd_quintile,
        },
        intervals=months(12).starting_on(start_date),
    )

    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_sex",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "sex": sex,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )
    
    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_ethnicity",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "ethnicity": ethnicity,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )

    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_imd_quintile",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "imd_quintile": imd_quintile,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )

    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_age_sex",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "age_band": age_band,
    #         "sex": sex,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )
    
    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_age_ethnicity",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "age_band": age_band,
    #         "ethnicity": ethnicity,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )

    # measures.define_measure(
    #     name=f"count_virtual_{time_description}_monthly_age_imd_quintile",
    #     numerator=count_virtual_consultation,
    #     denominator=count_appointment,
    #     group_by={
    #         "age_band": age_band,
    #         "imd_quintile": imd_quintile,
    #     },
    #     intervals=months(12).starting_on(start_date),
    # )