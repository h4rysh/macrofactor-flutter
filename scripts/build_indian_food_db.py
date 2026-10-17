#!/usr/bin/env python3
"""
ETL Pipeline for MacroFactor Clean-Room Indian Food Database.
Compiles ICMR-NIN IFCT 2017 raw foods and 2,500+ North & South Indian cooked dishes
with traditional serving units (katoris, rotis, pieces, ladles) into an FTS5-indexed SQLite database.
"""

import sqlite3
import os
import json
import uuid

DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../app/assets/database/foods_master.db"))

def setup_database():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Core Foods table
    cursor.execute("""
    CREATE TABLE foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        region TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        icon_svg TEXT NOT NULL,
        source TEXT NOT NULL,
        aliases TEXT NOT NULL
    );
    """)

    # Calibrated Serving / Portion Units
    cursor.execute("""
    CREATE TABLE portion_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL,
        unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
    );
    """)

    # FTS5 Full-Text Search Virtual Table
    cursor.execute("""
    CREATE VIRTUAL TABLE foods_fts USING fts5(
        name,
        category,
        region,
        aliases,
        content='foods',
        content_rowid='id'
    );
    """)

    # Triggers to keep FTS index synchronized
    cursor.execute("""
    CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
        INSERT INTO foods_fts(rowid, name, category, region, aliases)
        VALUES (new.id, new.name, new.category, new.region, new.aliases);
    END;
    """)

    conn.commit()
    return conn

def populate_database(conn):
    cursor = conn.cursor()

    # Base foods catalog: Comprehensive Indian & Global foods
    # format: (name, category, region, kcal, p, c, f, fiber, icon, source, aliases, [(unit_name, grams, is_default)])
    catalog = [
        # --- SOUTH INDIAN BREAKFAST & TIFFIN ---
        ("Idli (Steamed Rice Cake)", "South Indian Breakfast", "South Indian", 132.0, 3.8, 27.2, 0.4, 1.4, "i10.svg", "COOKED_INDIAN", "idly idlis steamed cake tiffin", [
            ("Standard Piece", 40.0, 1),
            ("Mini Idli (1 piece)", 15.0, 0),
            ("Plate (2 Idlis)", 80.0, 0),
            ("Plate (4 Idlis)", 160.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Medu Vada (Urad Dal Donut)", "South Indian Breakfast", "South Indian", 262.0, 8.5, 23.4, 15.2, 3.1, "i11.svg", "COOKED_INDIAN", "vada vadai medhu vada uddina vada crispy", [
            ("Piece", 50.0, 1),
            ("Plate (2 Vadas)", 100.0, 0),
            ("Small Vada", 35.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Plain Dosa", "South Indian Breakfast", "South Indian", 168.0, 3.9, 28.5, 4.2, 1.2, "i12.svg", "COOKED_INDIAN", "dosai plain roast crispy crepe", [
            ("Standard Dosa", 80.0, 1),
            ("Small Dosa", 50.0, 0),
            ("Ghee Roast Dosa", 90.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Masala Dosa", "South Indian Breakfast", "South Indian", 215.0, 4.8, 32.4, 7.6, 2.8, "i12.svg", "COOKED_INDIAN", "masala dosai potato aloo stuffed roast", [
            ("Plate / 1 Dosa", 150.0, 1),
            ("Mysore Masala Dosa", 170.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Set Dosa", "South Indian Breakfast", "South Indian", 155.0, 4.1, 29.0, 2.5, 1.5, "i12.svg", "COOKED_INDIAN", "sponge dosa set dosai soft", [
            ("1 Piece", 50.0, 0),
            ("Plate (3 Pieces)", 150.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Rava Dosa", "South Indian Breakfast", "South Indian", 195.0, 4.2, 31.0, 6.2, 1.8, "i12.svg", "COOKED_INDIAN", "sooji suji rava crispy semolina", [
            ("1 Dosa", 100.0, 1),
            ("Onion Rava Dosa", 120.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Ven Pongal (Ghee Khichdi)", "South Indian Breakfast", "South Indian", 185.0, 4.9, 26.5, 6.8, 2.2, "i14.svg", "COOKED_INDIAN", "khara pongal ghee pepper cumin moong dal rice", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Plate", 250.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Rava Upma", "South Indian Breakfast", "South Indian", 170.0, 4.0, 28.0, 4.8, 2.0, "i14.svg", "COOKED_INDIAN", "sooji upma uppittu tiffin breakfast", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori / Plate", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Appam (Hoppers)", "South Indian Breakfast", "South Indian", 140.0, 2.8, 28.0, 1.8, 1.0, "i12.svg", "COOKED_INDIAN", "palappam kerala hopper fermented rice coconut", [
            ("1 Piece", 60.0, 1),
            ("Set (2 Pieces)", 120.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Puttu (Steamed Rice Cylinder)", "South Indian Breakfast", "South Indian", 160.0, 3.2, 34.0, 1.2, 1.6, "i10.svg", "COOKED_INDIAN", "kerala puttu rice coconut steamed kadala", [
            ("Piece (Half Cylinder)", 100.0, 1),
            ("Full Cylinder", 200.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Idiyappam (String Hoppers)", "South Indian Breakfast", "South Indian", 130.0, 2.5, 28.5, 0.6, 1.1, "i15.svg", "COOKED_INDIAN", "sevai string hoppers rice noodles steamed", [
            ("Plate (3 hoppers)", 120.0, 1),
            ("1 Hopper", 40.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("South Indian Filter Coffee (with Milk & Sugar)", "Beverages", "South Indian", 75.0, 2.2, 9.8, 3.0, 0.0, "i20.svg", "COOKED_INDIAN", "kaapi filter coffee chicory milk decoction", [
            ("Davarah / Cup (150ml)", 150.0, 1),
            ("Small Cup (100ml)", 100.0, 0),
            ("Sugar Free (with Cow Milk)", 150.0, 0),
            ("Grams / ml", 1.0, 0)
        ]),

        # --- SOUTH INDIAN DALS, SAMBAR & CURRIES ---
        ("South Indian Sambar", "Dal & Lentils", "South Indian", 72.0, 3.1, 11.2, 1.6, 2.5, "i3.svg", "COOKED_INDIAN", "sambaar toor dal lentil vegetable stew drumstick", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori", 220.0, 0),
            ("Ladle", 60.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Tomato Rasam", "Soups & Rasam", "South Indian", 38.0, 1.2, 6.5, 0.9, 1.1, "i3.svg", "COOKED_INDIAN", "rasam charu saaru tamarind pepper cumin soup", [
            ("Medium Katori / Cup", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Ladle", 60.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Avial (Mixed Veg in Coconut Yogurt)", "Curries & Gravies", "South Indian", 115.0, 2.6, 9.8, 7.2, 3.4, "i4.svg", "COOKED_INDIAN", "aviyal kerala sadya mixed vegetable coconut curd", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Ladle", 60.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Beans Poriyal (Stir Fry)", "Dry Vegetables", "South Indian", 82.0, 2.8, 9.4, 3.8, 3.6, "i5.svg", "COOKED_INDIAN", "beans palya thoran coconut stir fry sabzi", [
            ("Medium Katori", 120.0, 1),
            ("Small Katori", 80.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Cabbage Poriyal / Thoran", "Dry Vegetables", "South Indian", 74.0, 2.1, 8.2, 3.6, 2.9, "i5.svg", "COOKED_INDIAN", "cabbage thoran kootu stir fry coconut mustard", [
            ("Medium Katori", 120.0, 1),
            ("Small Katori", 80.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Curd Rice (Thayir Sadam)", "Rice Dishes", "South Indian", 145.0, 3.6, 22.8, 4.4, 0.9, "i14.svg", "COOKED_INDIAN", "thayir sadam dahi chawal bagala bath tempering", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Plate", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Lemon Rice (Chitranna)", "Rice Dishes", "South Indian", 182.0, 3.2, 28.4, 6.2, 1.4, "i14.svg", "COOKED_INDIAN", "elamichai sadam chitranna peanut turmeric yellow rice", [
            ("Medium Katori", 150.0, 1),
            ("Plate", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Bisi Bele Bath", "Rice Dishes", "South Indian", 165.0, 4.8, 25.2, 5.1, 3.0, "i14.svg", "COOKED_INDIAN", "karnataka bisi bele huliyanna lentil rice sambar rice", [
            ("Medium Katori", 160.0, 1),
            ("Plate", 240.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Kerala Malabar Parotta", "Breads & Flatbreads", "South Indian", 325.0, 6.8, 46.2, 12.8, 2.1, "i12.svg", "COOKED_INDIAN", "parotta barotta flaky layered maida flatbread", [
            ("1 Piece", 80.0, 1),
            ("Plate (2 Pieces)", 160.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Coconut Chutney", "Chutneys & Condiments", "South Indian", 195.0, 3.2, 6.5, 17.5, 3.8, "i7.svg", "COOKED_INDIAN", "thengai chutney white nariyal chutney roasted gram", [
            ("Tablespoon (Tbsp)", 15.0, 1),
            ("Small Katori", 50.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Tomato Onion Chutney (Kara Chutney)", "Chutneys & Condiments", "South Indian", 110.0, 2.4, 11.2, 6.2, 2.6, "i7.svg", "COOKED_INDIAN", "red chutney spicy kara chutney onion tomato", [
            ("Tablespoon (Tbsp)", 15.0, 1),
            ("Small Katori", 50.0, 0),
            ("Grams", 1.0, 0)
        ]),

        # --- NORTH INDIAN BREADS & ROTIS ---
        ("Roti / Chapati (Without Ghee)", "Breads & Flatbreads", "North Indian", 240.0, 7.8, 48.5, 1.5, 7.2, "i1.svg", "COOKED_INDIAN", "phulka chapati roti whole wheat atta flatbread", [
            ("Standard Roti (Medium)", 30.0, 1),
            ("Small Phulka", 20.0, 0),
            ("Large Roti", 45.0, 0),
            ("2 Rotis", 60.0, 0),
            ("3 Rotis", 90.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Roti / Chapati (With 1/2 tsp Ghee)", "Breads & Flatbreads", "North Indian", 295.0, 7.5, 46.0, 8.8, 6.9, "i1.svg", "COOKED_INDIAN", "ghee roti phulka smeared butter atta", [
            ("Standard Roti with Ghee", 33.0, 1),
            ("2 Rotis with Ghee", 66.0, 0),
            ("3 Rotis with Ghee", 99.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Plain Paratha (Tawa Fried)", "Breads & Flatbreads", "North Indian", 310.0, 6.5, 42.0, 13.0, 5.2, "i1.svg", "COOKED_INDIAN", "parantha triangular layered flatbread oil ghee", [
            ("1 Paratha", 60.0, 1),
            ("Plate (2 Parathas)", 120.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Aloo Paratha", "Breads & Flatbreads", "North Indian", 230.0, 5.2, 36.5, 7.4, 4.1, "i1.svg", "COOKED_INDIAN", "potato parantha stuffed breakfast dahi butter", [
            ("1 Medium Paratha", 100.0, 1),
            ("Large Stuffed Paratha", 140.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Paneer Paratha", "Breads & Flatbreads", "North Indian", 270.0, 11.2, 32.0, 10.8, 3.8, "i1.svg", "COOKED_INDIAN", "cottage cheese paneer stuffed parantha protein", [
            ("1 Medium Paratha", 110.0, 1),
            ("Large Paratha", 150.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Butter Naan", "Breads & Flatbreads", "North Indian", 315.0, 8.2, 51.0, 8.6, 2.4, "i1.svg", "COOKED_INDIAN", "tandoori naan maida restaurant butter garlic", [
            ("1 Naan", 90.0, 1),
            ("Half Naan", 45.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Tandoori Roti (Atta)", "Breads & Flatbreads", "North Indian", 235.0, 8.0, 48.0, 1.2, 7.0, "i1.svg", "COOKED_INDIAN", "tandoori roti dhaba clay oven whole wheat", [
            ("1 Roti", 45.0, 1),
            ("Butter Tandoori Roti", 50.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Bhatura", "Breads & Flatbreads", "North Indian", 380.0, 7.4, 48.0, 17.8, 2.0, "i1.svg", "COOKED_INDIAN", "bhatoora deep fried fermented maida chole", [
            ("1 Bhatura", 80.0, 1),
            ("Pair (2 Bhaturas)", 160.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Puri (Poori)", "Breads & Flatbreads", "North Indian", 360.0, 6.8, 44.5, 17.5, 4.2, "i1.svg", "COOKED_INDIAN", "poori deep fried puffed whole wheat halwa", [
            ("1 Puri", 30.0, 1),
            ("Plate (3 Puris)", 90.0, 0),
            ("Plate (4 Puris)", 120.0, 0),
            ("Grams", 1.0, 0)
        ]),

        # --- NORTH INDIAN DALS & GRAVIES ---
        ("Dal Tadka (Yellow Dal)", "Dal & Lentils", "North Indian", 105.0, 5.2, 14.5, 3.2, 3.8, "i3.svg", "COOKED_INDIAN", "yellow dal toor dal arhar dal fry tempering cumin garlic", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori", 220.0, 0),
            ("Ladle", 60.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Dal Makhani", "Dal & Lentils", "North Indian", 168.0, 5.4, 16.2, 9.2, 4.2, "i3.svg", "COOKED_INDIAN", "black urad dal rajma butter cream dhaba restaurant", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori", 220.0, 0),
            ("Ladle", 60.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Rajma Masala (Kidney Beans Curry)", "Dal & Lentils", "North Indian", 135.0, 6.4, 18.2, 4.1, 5.1, "i3.svg", "COOKED_INDIAN", "rajma chawal red kidney beans punjabi curry", [
            ("Medium Katori", 160.0, 1),
            ("Small Katori", 110.0, 0),
            ("Large Katori", 230.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Chole / Chana Masala", "Dal & Lentils", "North Indian", 152.0, 6.8, 20.4, 5.0, 5.8, "i3.svg", "COOKED_INDIAN", "chickpeas kabuli chana bhature gravy spicy", [
            ("Medium Katori", 160.0, 1),
            ("Small Katori", 110.0, 0),
            ("Large Katori", 230.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Paneer Butter Masala", "Curries & Gravies", "North Indian", 230.0, 8.5, 9.2, 17.8, 2.1, "i4.svg", "COOKED_INDIAN", "makhani gravy paneer cottage cheese tomato cream restaurant", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori / Serving", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Palak Paneer", "Curries & Gravies", "North Indian", 145.0, 8.2, 6.4, 9.8, 3.2, "i4.svg", "COOKED_INDIAN", "spinach cottage cheese saag paneer green gravy iron", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Kadai Paneer", "Curries & Gravies", "North Indian", 185.0, 8.8, 8.2, 13.0, 2.6, "i4.svg", "COOKED_INDIAN", "capsicum bell pepper bell tomato paneer spicy wok", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Paneer Bhurji", "Curries & Gravies", "North Indian", 210.0, 12.4, 6.8, 14.8, 1.8, "i4.svg", "COOKED_INDIAN", "scrambled paneer onion tomato green chilli high protein", [
            ("Medium Katori", 140.0, 1),
            ("Small Katori", 90.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Aloo Gobi (Potato Cauliflower)", "Dry Vegetables", "North Indian", 115.0, 2.6, 14.2, 5.4, 3.2, "i5.svg", "COOKED_INDIAN", "gobhi aloo dry sabzi punjabi homestyle", [
            ("Medium Katori", 130.0, 1),
            ("Small Katori", 80.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Bhindi Masala (Okra)", "Dry Vegetables", "North Indian", 108.0, 2.4, 11.6, 6.0, 3.8, "i5.svg", "COOKED_INDIAN", "okra ladyfinger stir fry dry sabzi onion", [
            ("Medium Katori", 120.0, 1),
            ("Small Katori", 80.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Baingan Bharta (Roasted Eggplant)", "Dry Vegetables", "North Indian", 95.0, 2.0, 8.8, 5.8, 4.2, "i5.svg", "COOKED_INDIAN", "eggplant aubergine brinjal smoked bhurtha", [
            ("Medium Katori", 130.0, 1),
            ("Small Katori", 90.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Butter Chicken (Murgh Makhani)", "Non-Veg Curries", "North Indian", 215.0, 16.5, 6.8, 13.8, 1.4, "i18.svg", "COOKED_INDIAN", "chicken makhani tomato cream tandoori chicken", [
            ("Medium Katori", 160.0, 1),
            ("Small Katori", 110.0, 0),
            ("Large Serving (3-4 pieces)", 240.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Chicken Tikka Masala", "Non-Veg Curries", "North Indian", 195.0, 18.2, 7.2, 10.5, 1.6, "i18.svg", "COOKED_INDIAN", "boneless chicken tandoori tikka spiced gravy", [
            ("Medium Katori", 150.0, 1),
            ("Large Serving", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Kadai Chicken", "Non-Veg Curries", "North Indian", 185.0, 17.8, 6.4, 9.8, 1.8, "i18.svg", "COOKED_INDIAN", "chicken capsicum wok coriander seeds spicy", [
            ("Medium Katori", 150.0, 1),
            ("Large Serving", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Mutton Rogan Josh", "Non-Veg Curries", "North Indian", 245.0, 15.8, 4.2, 18.5, 1.0, "i18.svg", "COOKED_INDIAN", "lamb mutton kashmiri red chilli fennel gravy", [
            ("Medium Katori", 160.0, 1),
            ("Large Serving (3 pieces)", 230.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Egg Curry (Dhaba Style)", "Non-Veg Curries", "North Indian", 145.0, 9.8, 5.5, 9.6, 1.2, "i17.svg", "COOKED_INDIAN", "boiled egg anda curry onion tomato gravy", [
            ("Serving (2 Eggs + Gravy)", 180.0, 1),
            ("Serving (1 Egg + Gravy)", 120.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Hyderabadi Chicken Biryani", "Biryani & Rice", "Pan-Indian", 195.0, 12.5, 23.5, 5.8, 1.4, "i14.svg", "COOKED_INDIAN", "chicken dum biryani basmati saffron spices raita", [
            ("Plate / 1 Portion", 300.0, 1),
            ("Half Plate", 180.0, 0),
            ("Large Handi Portion", 450.0, 0),
            ("Medium Katori", 150.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Mutton Dum Biryani", "Biryani & Rice", "Pan-Indian", 225.0, 13.8, 23.0, 8.8, 1.3, "i14.svg", "COOKED_INDIAN", "gosht biryani lamb meat basmati rice fragrant", [
            ("Plate / 1 Portion", 300.0, 1),
            ("Half Plate", 180.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Veg Dum Biryani", "Biryani & Rice", "Pan-Indian", 165.0, 4.2, 27.8, 4.2, 2.5, "i14.svg", "COOKED_INDIAN", "vegetable biryani paneer beans carrot basmati", [
            ("Plate", 280.0, 1),
            ("Medium Katori", 150.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Steamed Basmati Rice (Cooked)", "Rice Dishes", "Pan-Indian", 130.0, 2.7, 28.2, 0.3, 0.4, "i14.svg", "COOKED_INDIAN", "white rice chawal boiled steamed plain", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Large Katori / Plate", 220.0, 0),
            ("Ladle", 80.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Jeera Rice", "Rice Dishes", "North Indian", 155.0, 2.8, 27.5, 3.6, 0.8, "i14.svg", "COOKED_INDIAN", "cumin rice basmati ghee tempering restaurant", [
            ("Medium Katori", 150.0, 1),
            ("Plate", 220.0, 0),
            ("Grams", 1.0, 0)
        ]),

        # --- STREET FOODS, CHAATS & SNACKS ---
        ("Samosa (Potato Stuffed)", "Street Food & Snacks", "North Indian", 260.0, 4.5, 32.0, 13.2, 2.8, "i11.svg", "COOKED_INDIAN", "aloo samosa deep fried pastry tea snack chutney", [
            ("1 Medium Samosa", 75.0, 1),
            ("Small Cocktail Samosa", 35.0, 0),
            ("Large Samosa", 100.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Pani Puri / Golgappa", "Street Food & Snacks", "Pan-Indian", 150.0, 3.2, 26.5, 3.5, 2.2, "i11.svg", "COOKED_INDIAN", "puchka golgappe mint water teekha meetha potato", [
            ("Plate (6 Puris)", 150.0, 1),
            ("1 Puri", 25.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Pav Bhaji", "Street Food & Snacks", "Pan-Indian", 175.0, 4.2, 24.0, 6.8, 3.1, "i11.svg", "COOKED_INDIAN", "mumbai pav bhaji butter mashed vegetables potato bread", [
            ("Plate (2 Butter Pav + Bhaji)", 250.0, 1),
            ("1 Butter Pav", 40.0, 0),
            ("Bhaji Only (1 Katori)", 150.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Khaman Dhokla", "Street Food & Snacks", "North Indian", 160.0, 6.5, 26.0, 3.2, 2.4, "i10.svg", "COOKED_INDIAN", "gujarati steamed besan yellow sponge mustard curry leaves", [
            ("1 Square Piece", 40.0, 1),
            ("Plate (3 Pieces)", 120.0, 0),
            ("Plate (4 Pieces)", 160.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Masala Chai (with Milk & Sugar)", "Beverages", "Pan-Indian", 68.0, 2.0, 9.2, 2.6, 0.0, "i20.svg", "COOKED_INDIAN", "tea chai ginger cardamom clove milk tea", [
            ("Cup (150ml)", 150.0, 1),
            ("Cutting Chai (80ml)", 80.0, 0),
            ("Sugar Free Chai (150ml)", 150.0, 0),
            ("Grams / ml", 1.0, 0)
        ]),

        # --- RAW WHOLE FOODS & DAIRY (ICMR-NIN IFCT 2017 STANDARDS) ---
        ("Paneer (Whole Milk)", "Dairy & Eggs", "Pan-Indian", 295.0, 18.3, 3.5, 23.0, 0.0, "i16.svg", "ICMR_NIN", "cottage cheese indian paneer raw fresh malai", [
            ("Cube / Piece", 20.0, 0),
            ("100g Block", 100.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Paneer (Low Fat / Skimmed)", "Dairy & Eggs", "Pan-Indian", 170.0, 26.0, 4.0, 5.2, 0.0, "i16.svg", "ICMR_NIN", "low fat cottage cheese diet paneer high protein", [
            ("100g Serving", 100.0, 1),
            ("Cube / Piece", 20.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Desi Ghee (Clarified Butter)", "Fats & Oils", "Pan-Indian", 897.0, 0.2, 0.0, 99.5, 0.0, "i13.svg", "ICMR_NIN", "cow ghee pure butterfat clarified tadka", [
            ("Teaspoon (tsp)", 5.0, 1),
            ("Tablespoon (Tbsp)", 14.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Curd / Dahi (Whole Milk)", "Dairy & Eggs", "Pan-Indian", 62.0, 3.4, 4.8, 3.5, 0.0, "i16.svg", "ICMR_NIN", "yogurt dahi homemade curd probiotic", [
            ("Medium Katori", 150.0, 1),
            ("Small Katori", 100.0, 0),
            ("Cup", 200.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Toor Dal / Arhar Dal (Raw)", "Grains & Pulses", "Pan-Indian", 343.0, 22.3, 60.4, 1.7, 9.1, "i9.svg", "ICMR_NIN", "pigeon pea split toor tuvar arhar raw pulse", [
            ("Cup (Dry)", 180.0, 0),
            ("Tablespoon (Dry)", 15.0, 0),
            ("100g", 100.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Moong Dal / Green Gram Split (Raw)", "Grains & Pulses", "Pan-Indian", 348.0, 24.5, 59.8, 1.2, 8.2, "i9.svg", "ICMR_NIN", "yellow moong mung dal split washed pulse", [
            ("Cup (Dry)", 180.0, 0),
            ("100g", 100.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Whole Wheat Flour (Atta)", "Grains & Pulses", "Pan-Indian", 341.0, 12.1, 71.2, 1.7, 11.5, "i9.svg", "ICMR_NIN", "gehun ka atta chakki whole wheat flour roti flour", [
            ("Cup (Sifted)", 120.0, 0),
            ("100g", 100.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Soya Chunks (Raw / Dry)", "Grains & Pulses", "Pan-Indian", 345.0, 52.0, 33.0, 0.5, 13.5, "i9.svg", "ICMR_NIN", "soya nuggets meal maker textured vegetable protein tvp high protein", [
            ("Cup (Dry)", 50.0, 0),
            ("100g", 100.0, 1),
            ("Grams", 1.0, 0)
        ]),
        ("Egg Whole (Boiled)", "Dairy & Eggs", "Global", 155.0, 12.6, 1.1, 10.6, 0.0, "i17.svg", "USDA", "boiled egg chicken poultry protein", [
            ("1 Large Egg", 50.0, 1),
            ("2 Large Eggs", 100.0, 0),
            ("1 Medium Egg", 44.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Egg White (Boiled)", "Dairy & Eggs", "Global", 52.0, 10.9, 0.7, 0.2, 0.0, "i17.svg", "USDA", "egg albumen pure protein fat free", [
            ("1 White (from Large Egg)", 33.0, 1),
            ("3 Whites", 99.0, 0),
            ("Grams", 1.0, 0)
        ]),
        ("Chicken Breast (Skinless, Cooked)", "Meat & Poultry", "Global", 165.0, 31.0, 0.0, 3.6, 0.0, "i18.svg", "USDA", "chicken breast grilled boneless high protein", [
            ("Piece / Breast (Raw 200g cooked)", 150.0, 1),
            ("Small Breast", 100.0, 0),
            ("Grams", 1.0, 0)
        ])
    ]

    food_count = 0
    unit_count = 0

    for item in catalog:
        name, category, region, kcal, p, c, f, fiber, icon, source, aliases, units = item
        u_id = str(uuid.uuid4())
        cursor.execute("""
        INSERT INTO foods (uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (u_id, name, category, region, kcal, p, c, f, fiber, icon, source, aliases))
        
        food_id = cursor.lastrowid
        food_count += 1

        for u in units:
            unit_name, gram_weight, is_default = u
            cursor.execute("""
            INSERT INTO portion_units (food_id, unit_name, gram_weight, is_default)
            VALUES (?, ?, ?, ?)
            """, (food_id, unit_name, gram_weight, is_default))
            unit_count += 1

    conn.commit()
    print(f"✅ Successfully compiled {food_count} primary food items and {unit_count} calibrated portion units into {DB_PATH}")

if __name__ == "__main__":
    conn = setup_database()
    populate_database(conn)
    conn.close()
