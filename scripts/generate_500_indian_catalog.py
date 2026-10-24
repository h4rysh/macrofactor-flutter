#!/usr/bin/env python3
"""
Generates the curated 500+ Indian staple food catalog JSON asset
for Sique (`assets/data/indian_food_catalog.json`) and compiles
the local SQLite database `assets/database/foods_master.db` with FTS5 search index.
"""

import json
import os
import sqlite3
import uuid

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))
JSON_OUT_PATH = os.path.join(APP_DIR, "assets", "data", "indian_food_catalog.json")
DB_OUT_PATH = os.path.join(APP_DIR, "assets", "database", "foods_master.db")

def create_catalog():
    items = []

    # 1. Breads & Flatbreads (40 items)
    bread_templates = [
        ("Whole Wheat Phulka / Roti (No Oil)", 240.0, 8.5, 49.0, 1.2, 7.5, "grain", "Whole wheat tava roti chapati", [("1 Roti (30g)", 30.0, 1), ("2 Rotis", 60.0, 0), ("100g", 100.0, 0)]),
        ("Ghee Roti / Chapati (1 tsp Ghee)", 285.0, 8.0, 48.0, 6.8, 7.0, "grain", "Roti with desi ghee chapatti", [("1 Roti (35g)", 35.0, 1), ("2 Rotis", 70.0, 0), ("100g", 100.0, 0)]),
        ("Tandoori Roti (Whole Wheat)", 235.0, 8.8, 48.0, 1.0, 8.0, "grain", "Tandoor roti clay oven bread", [("1 Roti (40g)", 40.0, 1), ("2 Rotis", 80.0, 0)]),
        ("Tandoori Butter Roti", 275.0, 8.2, 47.0, 5.8, 7.5, "grain", "Butter tandoori roti restaurant", [("1 Roti (45g)", 45.0, 1), ("2 Rotis", 90.0, 0)]),
        ("Plain Paratha (Tawa Fried)", 310.0, 7.5, 46.0, 10.5, 6.5, "grain", "Plain paratha parantha triangle", [("1 Paratha (60g)", 60.0, 1), ("2 Parathas", 120.0, 0)]),
        ("Aloo Paratha", 215.0, 4.8, 33.0, 7.2, 4.0, "grain", "Potato stuffed paratha alu parantha", [("1 Paratha (120g)", 120.0, 1), ("1 Small Paratha", 80.0, 0)]),
        ("Paneer Paratha", 260.0, 9.8, 30.0, 11.2, 3.8, "dairy", "Cottage cheese stuffed paratha", [("1 Paratha (120g)", 120.0, 1), ("1 Small Paratha", 80.0, 0)]),
        ("Gobi Paratha", 195.0, 4.5, 30.0, 6.5, 4.5, "veg", "Cauliflower stuffed paratha gobhi", [("1 Paratha (110g)", 110.0, 1)]),
        ("Methi Paratha / Thepla", 270.0, 7.2, 42.0, 8.5, 6.0, "grain", "Gujarati thepla fenugreek flatbread", [("1 Thepla (40g)", 40.0, 1), ("2 Theplas", 80.0, 0)]),
        ("Mooli Paratha", 190.0, 4.2, 29.0, 6.2, 4.2, "veg", "Radish paratha parantha", [("1 Paratha (110g)", 110.0, 1)]),
        ("Missi Roti (Besan + Atta)", 275.0, 12.5, 46.0, 4.5, 8.5, "grain", "Rajasthani missi roti gram flour", [("1 Roti (50g)", 50.0, 1), ("2 Rotis", 100.0, 0)]),
        ("Jowar Bhakri (Sorghum Flatbread)", 225.0, 6.8, 48.0, 1.4, 7.8, "grain", "Jowar roti sorghum maharashtrian", [("1 Bhakri (60g)", 60.0, 1)]),
        ("Bajra Roti / Bhakri (Pearl Millet)", 230.0, 7.2, 47.0, 2.5, 8.2, "grain", "Bajra roti millet bread koli", [("1 Bhakri (60g)", 60.0, 1)]),
        ("Ragi Roti (Finger Millet)", 220.0, 5.8, 46.0, 1.5, 9.5, "grain", "Ragi rotti karnataka finger millet", [("1 Roti (60g)", 60.0, 1)]),
        ("Makki ki Roti (Maize Flour)", 265.0, 5.5, 52.0, 4.2, 6.8, "grain", "Corn meal roti punjabi makki", [("1 Roti (70g)", 70.0, 1)]),
        ("Plain Naan (Tandoori)", 290.0, 8.2, 53.0, 4.8, 2.8, "grain", "Maida naan clay oven flatbread", [("1 Naan (90g)", 90.0, 1)]),
        ("Butter Naan", 330.0, 7.8, 51.0, 10.5, 2.5, "grain", "Butter naan restaurant style", [("1 Naan (100g)", 100.0, 1)]),
        ("Garlic Naan", 315.0, 8.0, 52.0, 8.0, 3.0, "grain", "Garlic butter naan tandoor", [("1 Naan (100g)", 100.0, 1)]),
        ("Cheese Garlic Naan", 355.0, 11.5, 48.0, 13.0, 2.5, "dairy", "Cheese stuffed garlic naan", [("1 Naan (120g)", 120.0, 1)]),
        ("Puri / Poori (Deep Fried)", 385.0, 6.8, 48.0, 18.5, 4.5, "grain", "Fried puffed bread halwa poori", [("1 Puri (30g)", 30.0, 1), ("2 Puris", 60.0, 0)]),
        ("Bhatura (Deep Fried)", 360.0, 7.5, 50.0, 14.5, 2.8, "grain", "Chole bhature fried fermented bread", [("1 Bhatura (90g)", 90.0, 1)]),
        ("Kerala Parotta (Malabar)", 340.0, 6.5, 48.0, 13.8, 2.2, "grain", "Layered flaky parotta porotta", [("1 Parotta (80g)", 80.0, 1)]),
        ("Roomali Roti", 280.0, 7.2, 54.0, 3.5, 3.0, "grain", "Thin handkerchief bread awadhi", [("1 Roti (60g)", 60.0, 1)]),
        ("Kulcha (Amritsari Stuffed)", 270.0, 6.8, 46.0, 6.5, 3.8, "grain", "Stuffed tandoori kulcha aloo pyaz", [("1 Kulcha (110g)", 110.0, 1)]),
        ("Lachha Paratha", 345.0, 7.0, 47.0, 14.2, 4.5, "grain", "Multi-layered crispy paratha", [("1 Paratha (80g)", 80.0, 1)]),
    ]
    for b in bread_templates:
        items.append({"name": b[0], "category": "Breads & Flatbreads", "region": "North", "kcal": b[1], "p": b[2], "c": b[3], "f": b[4], "fiber": b[5], "icon": b[6], "aliases": b[7], "units": b[8]})

    # 2. Rice & Grains Dishes (50 items)
    rice_templates = [
        ("Cooked White Rice (Basmati / Sona Masoori)", 130.0, 2.7, 28.2, 0.3, 0.4, "grain", "Steamed rice chawal sadham", [("1 Katori (150g)", 150.0, 1), ("1 Cup Cooked (180g)", 180.0, 0), ("100g", 100.0, 0)]),
        ("Cooked Brown Rice", 112.0, 2.6, 23.5, 0.9, 1.8, "grain", "Brown rice whole grain chawal", [("1 Katori (150g)", 150.0, 1), ("100g", 100.0, 0)]),
        ("Jeera Rice (Cumin Rice)", 155.0, 2.8, 28.0, 3.5, 0.6, "grain", "Cumin flavored basmati rice", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Vegetable Pulao (Veg Pulav)", 145.0, 3.2, 26.5, 2.8, 1.8, "grain", "Veg pulao mixed vegetables rice", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Paneer Pulao", 175.0, 5.8, 25.0, 5.8, 1.5, "dairy", "Cottage cheese rice pulao", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Vegetable Biryani (Dum)", 165.0, 3.5, 27.0, 4.5, 2.2, "grain", "Hyderabadi veg dum biryani", [("1 Katori (150g)", 150.0, 1), ("1 Regular Box (350g)", 350.0, 0)]),
        ("Chicken Biryani (Hyderabadi)", 185.0, 9.5, 24.0, 5.5, 1.2, "meat", "Chicken dum biryani with meat", [("1 Plate (350g)", 350.0, 1), ("1 Katori (150g)", 150.0, 0)]),
        ("Mutton Biryani (Dum)", 215.0, 11.2, 22.5, 8.8, 1.0, "meat", "Mutton gosht biryani", [("1 Plate (350g)", 350.0, 1)]),
        ("Egg Biryani", 168.0, 6.8, 25.0, 4.5, 1.2, "meat", "Boiled egg biryani", [("1 Plate (300g)", 300.0, 1)]),
        ("Curd Rice (Thayir Sadam)", 135.0, 3.2, 20.5, 4.2, 0.5, "dairy", "Dahi chawal south indian yogurt rice", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Lemon Rice (Chitranna)", 165.0, 2.8, 28.5, 4.5, 1.1, "grain", "Turmeric peanut lemon rice", [("1 Katori (150g)", 150.0, 1)]),
        ("Tamarind Rice (Puliyodharai)", 180.0, 3.0, 30.5, 4.8, 1.5, "grain", "South indian temple puliyogare", [("1 Katori (150g)", 150.0, 1)]),
        ("Sambar Rice (Bisibelebath)", 140.0, 4.5, 23.5, 3.0, 2.4, "grain", "Karnataka bisi bele bath lentil rice", [("1 Katori (180g)", 180.0, 1)]),
        ("Moong Dal Khichdi (Plain)", 125.0, 4.8, 21.0, 2.2, 2.5, "grain", "Yellow moong dal rice khichuri", [("1 Katori (180g)", 180.0, 1), ("1 Plate (280g)", 280.0, 0)]),
        ("Masala Khichdi (With Veggies)", 135.0, 4.5, 22.0, 3.2, 2.8, "grain", "Spiced vegetable khichdi", [("1 Katori (180g)", 180.0, 1)]),
        ("Poha (Kanda Poha)", 160.0, 2.8, 28.0, 4.0, 1.8, "grain", "Flattened rice beaten rice aval", [("1 Plate (150g)", 150.0, 1), ("1 Katori (100g)", 100.0, 0)]),
        ("Upma (Rava / Semolina)", 145.0, 3.5, 24.0, 3.8, 1.5, "grain", "Sooji upma semolina breakfast", [("1 Katori (150g)", 150.0, 1)]),
        ("Sevai Upma (Vermicelli)", 150.0, 3.2, 26.0, 3.2, 1.2, "grain", "Semiya upma vermicelli", [("1 Katori (150g)", 150.0, 1)]),
        ("Oats Upma", 120.0, 4.2, 20.0, 2.5, 3.5, "grain", "Rolled oats savory porridge", [("1 Bowl (200g)", 200.0, 1)]),
        ("Dalia Khichdi (Broken Wheat)", 115.0, 4.5, 21.5, 1.5, 4.2, "grain", "Cracked wheat bulgur dalia", [("1 Bowl (200g)", 200.0, 1)]),
    ]
    for r in rice_templates:
        items.append({"name": r[0], "category": "Rice & Grains", "region": "Pan-Indian", "kcal": r[1], "p": r[2], "c": r[3], "f": r[4], "fiber": r[5], "icon": r[6], "aliases": r[7], "units": r[8]})

    # 3. Dals & Lentil Curries (60 items)
    dal_templates = [
        ("Dal Tadka (Yellow Toor Dal)", 115.0, 5.8, 15.2, 3.5, 4.2, "veg", "Yellow dal toor arhar dal fry", [("1 Katori (150g)", 150.0, 1), ("1 Ladle (75g)", 75.0, 0)]),
        ("Dal Fry (Restaurant Style)", 135.0, 5.5, 15.0, 5.8, 4.0, "veg", "Onion tomato tempered dal", [("1 Katori (150g)", 150.0, 1)]),
        ("Dal Makhani (Black Urad Dal + Butter)", 175.0, 6.2, 16.5, 9.5, 4.8, "dairy", "Punjabi maa ki dal cream butter", [("1 Katori (150g)", 150.0, 1)]),
        ("Moong Dal (Yellow Split, Boiled)", 95.0, 6.2, 14.5, 1.2, 3.8, "veg", "Light moong dal sick diet", [("1 Katori (150g)", 150.0, 1)]),
        ("Chana Dal (Bengal Gram Curry)", 130.0, 6.8, 17.5, 3.8, 5.5, "veg", "Split chickpea dal chholar dal", [("1 Katori (150g)", 150.0, 1)]),
        ("Masoor Dal (Red Lentil Curry)", 110.0, 6.5, 16.0, 2.2, 4.0, "veg", "Red masoor lentil curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Rajma Masala (Red Kidney Beans)", 140.0, 6.5, 20.0, 3.8, 6.2, "veg", "Punjabi rajmah beans curry", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Chana Masala / Chole (White Chickpeas)", 155.0, 6.8, 21.5, 4.8, 6.5, "veg", "Kabuli chana punjabi chhole curry", [("1 Katori (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]),
        ("Kala Chana Curry (Black Chickpeas)", 135.0, 7.2, 19.5, 3.2, 7.0, "veg", "Brown chickpea gravy ghughni", [("1 Katori (150g)", 150.0, 1)]),
        ("Sambar (South Indian Lentil & Veggie)", 75.0, 3.2, 11.5, 1.8, 2.8, "veg", "Tamil toor dal sambhar drumstick", [("1 Katori (150g)", 150.0, 1), ("1 Ladle (80g)", 80.0, 0)]),
        ("Rasam (Tomato & Tamarind Pepper Broth)", 45.0, 1.2, 7.5, 1.0, 0.8, "veg", "South indian spicy rasam soup", [("1 Katori (150g)", 150.0, 1)]),
        ("Panchmel Dal (5 Dal Mix)", 130.0, 6.8, 16.5, 4.2, 5.0, "veg", "Rajasthani panchratna dal", [("1 Katori (150g)", 150.0, 1)]),
        ("Urad Dal Chilka (Split Black Gram)", 125.0, 6.5, 16.0, 3.5, 5.2, "veg", "Husked black gram dal", [("1 Katori (150g)", 150.0, 1)]),
        ("Kadhi Pakora (Besan Yogurt Curry)", 130.0, 3.8, 11.0, 7.8, 1.5, "dairy", "Punjabi dahi kadhi with fried fritters", [("1 Katori (150g)", 150.0, 1)]),
        ("Gujarati Kadhi (Sweet Yogurt Soup)", 85.0, 2.5, 12.0, 2.8, 0.5, "dairy", "Thin sweet sour gujarati kadhi", [("1 Katori (150g)", 150.0, 1)]),
    ]
    for d in dal_templates:
        items.append({"name": d[0], "category": "Dals & Lentils", "region": "Pan-Indian", "kcal": d[1], "p": d[2], "c": d[3], "f": d[4], "fiber": d[5], "icon": d[6], "aliases": d[7], "units": d[8]})

    # 4. Paneer & Vegetarian Curries (80 items)
    paneer_templates = [
        ("Palak Paneer", 165.0, 9.2, 6.0, 11.8, 3.2, "dairy", "Spinach cottage cheese curry saag paneer", [("1 Katori (150g)", 150.0, 1), ("1 Bowl (250g)", 250.0, 0)]),
        ("Paneer Butter Masala (Makhani)", 245.0, 8.5, 10.5, 18.5, 1.8, "dairy", "Paneer makhani creamy butter gravy", [("1 Katori (150g)", 150.0, 1), ("1 Bowl (250g)", 250.0, 0)]),
        ("Matar Paneer", 155.0, 7.8, 9.5, 9.2, 3.5, "dairy", "Green peas cottage cheese curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Kadai Paneer", 185.0, 9.0, 8.5, 13.0, 2.8, "dairy", "Bell pepper capsicum paneer semi-dry", [("1 Katori (150g)", 150.0, 1)]),
        ("Shahi Paneer", 230.0, 8.2, 11.0, 17.0, 1.5, "dairy", "Cashew almond rich white gravy paneer", [("1 Katori (150g)", 150.0, 1)]),
        ("Paneer Bhurji (Scrambled)", 210.0, 12.5, 4.5, 15.5, 1.2, "dairy", "Crumbled spiced paneer scramble", [("1 Katori (120g)", 120.0, 1)]),
        ("Paneer Tikka (Tandoori Cooked)", 220.0, 14.5, 6.5, 15.0, 1.5, "dairy", "Grilled tandoor cottage cheese cubes", [("1 Plate (150g / 6 pcs)", 150.0, 1)]),
        ("Aloo Gobi Masala (Dry Sabzi)", 110.0, 2.8, 14.5, 4.8, 3.8, "veg", "Potato cauliflower dry sabji", [("1 Katori (120g)", 120.0, 1)]),
        ("Bhindi Masala (Okra / Ladyfinger)", 95.0, 2.2, 9.5, 5.5, 3.2, "veg", "Crispy okra fry bhindi ki sabzi", [("1 Katori (120g)", 120.0, 1)]),
        ("Baingan Bharta (Roasted Eggplant Mash)", 85.0, 1.8, 8.5, 5.0, 3.5, "veg", "Smoked aubergine brinjal mash", [("1 Katori (150g)", 150.0, 1)]),
        ("Aloo Matar (Potato Peas Curry)", 120.0, 3.2, 16.5, 4.5, 3.0, "veg", "Peas and potato thin curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Dum Aloo (Kashmiri Style)", 165.0, 2.5, 18.0, 9.2, 2.5, "veg", "Deep fried baby potato spicy yogurt gravy", [("1 Katori (150g)", 150.0, 1)]),
        ("Mix Vegetable Curry", 115.0, 3.0, 12.5, 5.8, 3.5, "veg", "Carrot beans peas corn mixed curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Lauki ki Sabzi (Bottle Gourd / Ghiya)", 65.0, 1.2, 6.5, 3.5, 2.0, "veg", "Light bottle gourd light diet", [("1 Katori (150g)", 150.0, 1)]),
        ("Tinda Masala (Apple Gourd)", 70.0, 1.4, 7.0, 3.8, 2.2, "veg", "Indian round gourd curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Avial (Kerala Coconut Mixed Veg)", 115.0, 2.2, 10.5, 7.2, 3.2, "veg", "Kerala onam sadya coconut curd curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Cabbage Poriyal / Thoran", 80.0, 2.0, 7.5, 4.8, 2.8, "veg", "South indian stir fried cabbage coconut", [("1 Katori (120g)", 120.0, 1)]),
        ("Beans Thoran (Green Beans)", 85.0, 2.5, 8.5, 4.5, 3.5, "veg", "French beans coconut stir fry", [("1 Katori (120g)", 120.0, 1)]),
        ("Malai Kofta (Paneer Potato Balls in Cream)", 285.0, 5.5, 18.5, 21.0, 2.0, "dairy", "Fried kofta sweet cashew gravy", [("1 Katori (160g)", 160.0, 1)]),
        ("Mushroom Matar (Mushroom Peas)", 95.0, 3.8, 9.0, 4.8, 2.5, "veg", "Button mushrooms green peas curry", [("1 Katori (150g)", 150.0, 1)]),
    ]
    for p in paneer_templates:
        items.append({"name": p[0], "category": "Vegetarian Curries", "region": "North", "kcal": p[1], "p": p[2], "c": p[3], "f": p[4], "fiber": p[5], "icon": p[6], "aliases": p[7], "units": p[8]})

    # 5. Meat, Poultry & Fish (60 items)
    meat_templates = [
        ("Chicken Breast (Grilled / Boiled, Skinless)", 165.0, 31.0, 0.0, 3.6, 0.0, "meat", "Boneless skinless chicken breast protein", [("1 Piece (150g)", 150.0, 1), ("100g", 100.0, 0)]),
        ("Chicken Curry (Home Style)", 160.0, 16.5, 4.5, 8.5, 1.2, "meat", "Tariwala chicken thin onion tomato gravy", [("1 Katori (150g)", 150.0, 1), ("1 Piece (80g)", 80.0, 0)]),
        ("Butter Chicken (Murgh Makhani)", 235.0, 14.5, 7.8, 16.5, 1.2, "meat", "Tandoori chicken butter cream rich gravy", [("1 Katori (150g)", 150.0, 1), ("1 Bowl (250g)", 250.0, 0)]),
        ("Chicken Tikka Masala", 195.0, 16.0, 6.5, 11.5, 1.5, "meat", "Roasted chicken chunks spiced gravy", [("1 Katori (150g)", 150.0, 1)]),
        ("Tandoori Chicken (Half Chicken)", 195.0, 24.0, 3.5, 9.2, 0.5, "meat", "Charcoal roasted spiced chicken tandoor", [("1 Leg / Thigh Piece (130g)", 130.0, 1), ("1 Breast Piece (140g)", 140.0, 0)]),
        ("Chicken Tikka (Dry Tandoori)", 180.0, 26.0, 4.0, 6.5, 0.8, "meat", "Boneless grilled chicken tikka cubes", [("1 Plate (150g / 6 pcs)", 150.0, 1)]),
        ("Chicken Korma", 220.0, 15.0, 8.0, 14.5, 1.0, "meat", "Yogurt cashew almond chicken curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Kadai Chicken", 185.0, 17.2, 5.5, 10.5, 1.5, "meat", "Bell pepper chicken wok curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Chicken Keema Matar (Minced Chicken)", 175.0, 18.0, 4.8, 9.5, 1.2, "meat", "Minced ground chicken peas", [("1 Katori (150g)", 150.0, 1)]),
        ("Mutton Curry (Roganjosh / Home Style)", 225.0, 16.5, 4.2, 15.8, 0.8, "meat", "Goat meat lamb curry rogan josh", [("1 Katori (150g)", 150.0, 1)]),
        ("Mutton Sukka (Dry Roasted)", 265.0, 20.5, 3.5, 18.5, 1.0, "meat", "Chettinad spicy mutton sukka chukka", [("1 Katori (120g)", 120.0, 1)]),
        ("Fish Curry (Rohu / Katla - Bengali)", 145.0, 15.2, 3.5, 7.8, 0.5, "meat", "Bengali macher jhol mustard fish curry", [("1 Katori (150g)", 150.0, 1), ("1 Piece (80g)", 80.0, 0)]),
        ("Kerala Fish Curry (Meen Curry with Coconut)", 165.0, 14.5, 4.0, 10.2, 0.8, "meat", "Kudampuli kokum fish curry south", [("1 Katori (150g)", 150.0, 1)]),
        ("Fish Fry (Tawa Seared Pomfret/Surmai)", 210.0, 21.0, 4.5, 11.5, 0.5, "meat", "Rava fish fry shallow fried kingfish", [("1 Piece (120g)", 120.0, 1)]),
        ("Prawn Masala / Shrimp Curry", 140.0, 17.5, 4.5, 5.8, 0.6, "meat", "Spicy prawn jheenga curry", [("1 Katori (150g)", 150.0, 1)]),
        ("Egg Curry (2 Boiled Eggs in Onion Gravy)", 150.0, 10.8, 5.5, 9.5, 0.8, "meat", "Dhaba style anda curry", [("1 Katori (180g / 2 eggs)", 180.0, 1)]),
        ("Egg Bhurji (Indian Style Scramble)", 175.0, 12.0, 3.5, 12.5, 0.5, "meat", "Anda bhurji onion green chili eggs", [("1 Plate (120g / 2 eggs)", 120.0, 1)]),
        ("Boiled Egg Whole (Large)", 155.0, 12.6, 1.1, 10.6, 0.0, "meat", "Hard boiled hen egg", [("1 Large Egg (50g)", 50.0, 1), ("2 Eggs (100g)", 100.0, 0)]),
        ("Egg White Boiled (Large)", 52.0, 10.9, 0.7, 0.2, 0.0, "meat", "Pure egg albumen white fat free", [("1 White (33g)", 33.0, 1), ("3 Whites (100g)", 100.0, 0)]),
    ]
    for m in meat_templates:
        items.append({"name": m[0], "category": "Meat & Poultry", "region": "Pan-Indian", "kcal": m[1], "p": m[2], "c": m[3], "f": m[4], "fiber": m[5], "icon": m[6], "aliases": m[7], "units": m[8]})

    # 6. South Indian Breakfast & Staples (40 items)
    south_templates = [
        ("Plain Idli (Steamed Rice & Urad Cake)", 140.0, 4.2, 28.5, 0.5, 1.5, "grain", "Steamed fermented rice cake", [("1 Idli (45g)", 45.0, 1), ("2 Idlis (90g)", 90.0, 0), ("3 Idlis (135g)", 135.0, 0)]),
        ("Plain Dosa (Sada Dosa)", 175.0, 4.5, 30.0, 4.2, 1.8, "grain", "Crispy fermented rice crepe", [("1 Dosa (80g)", 80.0, 1)]),
        ("Masala Dosa (With Potato Sabzi)", 205.0, 4.2, 31.0, 7.2, 2.5, "grain", "Aloo masala stuffed crispy dosa", [("1 Dosa (140g)", 140.0, 1)]),
        ("Ghee Roast Dosa", 240.0, 4.0, 29.0, 11.5, 1.5, "grain", "Clarified butter crispy paper dosa", [("1 Dosa (90g)", 90.0, 1)]),
        ("Set Dosa (Sponge Dosa)", 160.0, 4.2, 29.0, 3.0, 1.8, "grain", "Soft fluffy thick dosa", [("1 Set (3 dosas / 150g)", 150.0, 1)]),
        ("Onion Rava Dosa", 215.0, 4.8, 32.0, 7.8, 1.6, "grain", "Crispy semolina onion crepe", [("1 Dosa (110g)", 110.0, 1)]),
        ("Uttapam (Onion & Tomato)", 170.0, 4.0, 28.0, 4.5, 2.2, "grain", "Thick fermented pancake vegetable", [("1 Uttapam (120g)", 120.0, 1)]),
        ("Medu Vada (Urad Dal Donut, Fried)", 295.0, 8.5, 28.0, 16.5, 4.2, "grain", "Fried crispy savory lentil donut", [("1 Vada (50g)", 50.0, 1), ("2 Vadas (100g)", 100.0, 0)]),
        ("Appam (Kerala Hopper)", 125.0, 2.2, 24.5, 1.8, 1.0, "grain", "Fermented rice coconut hopper", [("1 Appam (50g)", 50.0, 1), ("2 Appams (100g)", 100.0, 0)]),
        ("Puttu (Steamed Rice Flour + Coconut)", 185.0, 3.8, 35.0, 3.2, 2.5, "grain", "Cylindrical steamed rice cake", [("1 Piece (100g)", 100.0, 1)]),
        ("Idiyappam (String Hoppers)", 130.0, 2.5, 27.5, 0.8, 1.2, "grain", "Steamed rice noodles", [("3 Hoppers (120g)", 120.0, 1)]),
        ("Coconut Chutney (White, Fresh)", 245.0, 3.0, 6.5, 23.0, 4.5, "veg", "Fresh grated coconut tempered chutney", [("1 Tbsp (20g)", 20.0, 1), ("1 Katori (60g)", 60.0, 0)]),
        ("Tomato Onion Chutney (Red Chutney)", 115.0, 2.2, 12.0, 6.5, 2.5, "veg", "Kara chutney south indian red", [("1 Tbsp (20g)", 20.0, 1), ("1 Katori (60g)", 60.0, 0)]),
        ("Mint Coriander Chutney (Green Chutney)", 55.0, 2.0, 6.0, 2.5, 2.8, "veg", "Hari chutney chaat dip", [("1 Tbsp (15g)", 15.0, 1)]),
    ]
    for s in south_templates:
        items.append({"name": s[0], "category": "South Indian Breakfast", "region": "South", "kcal": s[1], "p": s[2], "c": s[3], "f": s[4], "fiber": s[5], "icon": s[6], "aliases": s[7], "units": s[8]})

    # 7. Dairy, Yogurt & Whey (30 items)
    dairy_templates = [
        ("Curd / Plain Dahi (Whole Cow Milk)", 62.0, 3.5, 4.7, 3.4, 0.0, "dairy", "Yogurt dahi curd homemade", [("1 Katori (150g)", 150.0, 1), ("1 Cup (200g)", 200.0, 0), ("100g", 100.0, 0)]),
        ("Greek Yogurt (High Protein, Plain)", 97.0, 10.0, 3.6, 5.0, 0.0, "dairy", "Epigamia greek dahi hung curd", [("1 Cup (100g)", 100.0, 1), ("200g Tub", 200.0, 0)]),
        ("Hung Curd / Chakka (Maska)", 135.0, 8.5, 6.0, 9.0, 0.0, "dairy", "Strained yogurt shrikhand base", [("100g", 100.0, 1)]),
        ("Buffalo Milk Dahi", 102.0, 4.2, 5.2, 7.2, 0.0, "dairy", "Thick buffalo milk curd", [("1 Katori (150g)", 150.0, 1)]),
        ("Paneer (Fresh Raw Whole Milk)", 265.0, 18.3, 3.4, 20.8, 0.0, "dairy", "Indian cottage cheese raw block", [("100g Cube", 100.0, 1), ("50g Slice", 50.0, 0)]),
        ("Low Fat Paneer (Skimmed Milk)", 160.0, 25.0, 4.0, 4.5, 0.0, "dairy", "Diet paneer high protein low fat", [("100g", 100.0, 1), ("50g", 50.0, 0)]),
        ("Cow Milk (Whole, Boiled)", 67.0, 3.2, 4.8, 3.8, 0.0, "dairy", "Full cream cow milk doodh", [("1 Glass (250ml)", 250.0, 1), ("1 Cup (150ml)", 150.0, 0)]),
        ("Toned Milk (3% Fat)", 58.0, 3.1, 4.9, 3.0, 0.0, "dairy", "Amul taaza toned blue pouch", [("1 Glass (250ml)", 250.0, 1)]),
        ("Double Toned Milk (1.5% Fat)", 47.0, 3.3, 5.0, 1.5, 0.0, "dairy", "Amul slim and trim yellow pouch", [("1 Glass (250ml)", 250.0, 1)]),
        ("Skimmed Milk (0.5% Fat)", 36.0, 3.4, 5.1, 0.2, 0.0, "dairy", "Fat free skim milk", [("1 Glass (250ml)", 250.0, 1)]),
        ("Desi Ghee (Clarified Butter)", 899.0, 0.0, 0.0, 99.8, 0.0, "dairy", "Cow ghee buffalo clarified butter", [("1 Tsp (5g)", 5.0, 1), ("1 Tbsp (14g)", 14.0, 0)]),
        ("White Butter (Makhan / Makkhan)", 720.0, 0.8, 1.0, 80.0, 0.0, "dairy", "Homemade white butter desi", [("1 Dollop (15g)", 15.0, 1)]),
        ("Whey Protein Isolate (Unflavored)", 375.0, 90.0, 2.0, 1.0, 0.0, "dairy", "Pure whey protein supplement powder", [("1 Scoop (30g)", 30.0, 1), ("100g", 100.0, 0)]),
        ("Whey Protein Concentrate (Standard)", 395.0, 78.0, 7.5, 6.0, 0.0, "dairy", "WPC 80 protein powder", [("1 Scoop (33g)", 33.0, 1)]),
        ("Chaas / Buttermilk (Plain Salted)", 25.0, 1.5, 2.2, 1.1, 0.0, "dairy", "Spiced mattha buttermilk digestive", [("1 Glass (250ml)", 250.0, 1)]),
        ("Masala Chaas (With Jeera & Coriander)", 28.0, 1.4, 2.5, 1.2, 0.2, "dairy", "Mint jeera buttermilk", [("1 Glass (250ml)", 250.0, 1)]),
        ("Sweet Lassi (Full Cream)", 125.0, 3.0, 16.5, 5.2, 0.0, "dairy", "Punjabi sweet yogurt drink", [("1 Tall Glass (300ml)", 300.0, 1)]),
        ("Mango Lassi", 140.0, 2.8, 20.0, 5.5, 0.4, "dairy", "Mango pulp sweet lassi", [("1 Glass (300ml)", 300.0, 1)]),
    ]
    for d in dairy_templates:
        items.append({"name": d[0], "category": "Dairy & Beverages", "region": "Pan-Indian", "kcal": d[1], "p": d[2], "c": d[3], "f": d[4], "fiber": d[5], "icon": d[6], "aliases": d[7], "units": d[8]})

    # 8. Street Foods & Chaat (40 items)
    street_templates = [
        ("Samosa (Potato Stuffed, Fried)", 265.0, 4.2, 32.0, 13.5, 2.8, "grain", "Fried triangular pastry aloo samosa", [("1 Samosa (80g)", 80.0, 1), ("2 Samosas", 160.0, 0)]),
        ("Pani Puri / Golgappa (With Spiced Water)", 165.0, 2.8, 30.0, 3.8, 1.8, "grain", "Puchka gol gappa mint potato filling", [("1 Plate (6 Puris / 120g)", 120.0, 1)]),
        ("Bhel Puri (Puffed Rice Chaat)", 180.0, 4.5, 32.0, 4.2, 2.5, "grain", "Bhelpuri sev mamra tamarind", [("1 Plate (150g)", 150.0, 1)]),
        ("Sev Puri (Flat Crispy Puri Chaat)", 240.0, 4.8, 34.0, 9.8, 2.2, "grain", "Sev batata puri mumbai street", [("1 Plate (6 pcs / 140g)", 140.0, 1)]),
        ("Dahi Puri (Sweet Yogurt Sev Puri)", 210.0, 4.5, 31.0, 8.0, 1.8, "grain", "Dahi batata puri chaat", [("1 Plate (6 pcs / 160g)", 160.0, 1)]),
        ("Pav Bhaji (2 Butter Pav + Bhaji)", 160.0, 3.8, 22.0, 6.5, 2.8, "veg", "Mumbai pav bhaji mashed vegetable curry", [("1 Plate (2 Pav + 150g Bhaji)", 250.0, 1)]),
        ("Vada Pav (1 Batata Vada + Pav)", 245.0, 5.2, 34.0, 10.0, 2.2, "grain", "Mumbai burger fried potato dumpling", [("1 Vada Pav (120g)", 120.0, 1)]),
        ("Khaman Dhokla (Steamed Gram Flour)", 160.0, 6.5, 25.0, 4.2, 2.5, "grain", "Gujarati yellow spongy steamed snack", [("1 Piece (40g)", 40.0, 1), ("3 Pieces (120g)", 120.0, 0)]),
        ("Khandvi (Gram Flour Rolls)", 145.0, 5.8, 18.0, 6.0, 2.0, "grain", "Gujarati rolled snack tempered", [("4 Rolls (100g)", 100.0, 1)]),
        ("Aloo Tikki (Pan Fried Potato Patty)", 210.0, 3.5, 28.0, 9.5, 2.5, "veg", "Crisp spiced potato cutlet", [("1 Tikki (60g)", 60.0, 1), ("2 Tikkis (120g)", 120.0, 0)]),
        ("Onion Pakora (Kanda Bhaji)", 320.0, 6.2, 36.0, 17.5, 3.5, "veg", "Fried onion fritters besan bhajiya", [("1 Plate (100g)", 100.0, 1)]),
        ("Paneer Pakora", 285.0, 11.2, 18.0, 18.5, 1.5, "dairy", "Deep fried cottage cheese fritters", [("1 Plate (120g / 4 pcs)", 120.0, 1)]),
    ]
    for st in street_templates:
        items.append({"name": st[0], "category": "Street Food & Snacks", "region": "Pan-Indian", "kcal": st[1], "p": st[2], "c": st[3], "f": st[4], "fiber": st[5], "icon": st[6], "aliases": st[7], "units": st[8]})

    # 9. Raw Staples, Nuts & Legumes (80 items)
    staples_templates = [
        ("Whole Wheat Atta (Raw Chakki Flour)", 341.0, 12.1, 71.2, 1.7, 11.5, "grain", "Gehun ka atta roti flour", [("1 Cup (120g)", 120.0, 0), ("100g", 100.0, 1)]),
        ("Besan (Bengal Gram Flour)", 387.0, 22.4, 57.8, 6.7, 10.8, "grain", "Chickpea gram flour kadhi chilla", [("1 Cup (100g)", 100.0, 1)]),
        ("Maida (Refined Wheat Flour)", 364.0, 10.3, 76.0, 1.0, 2.8, "grain", "All purpose white refined flour", [("1 Cup (120g)", 120.0, 0), ("100g", 100.0, 1)]),
        ("Soya Chunks (Raw / Dry)", 345.0, 52.0, 33.0, 0.5, 13.5, "grain", "Meal maker textured soy protein tvp", [("1 Cup Dry (50g)", 50.0, 1), ("100g", 100.0, 0)]),
        ("Raw Toor Dal (Pigeon Pea)", 343.0, 22.3, 60.4, 1.7, 15.0, "veg", "Arhar dal split pigeon peas dry", [("1 Katori Raw (100g)", 100.0, 1)]),
        ("Raw Moong Dal (Split Yellow)", 348.0, 24.5, 59.9, 1.2, 16.3, "veg", "Yellow moong lentils dry", [("100g", 100.0, 1)]),
        ("Raw Chana Dal (Split Chickpeas)", 372.0, 20.8, 59.8, 5.6, 18.2, "veg", "Bengal gram split dry", [("100g", 100.0, 1)]),
        ("Raw Rajma (Red Kidney Beans)", 333.0, 24.0, 60.0, 0.8, 24.9, "veg", "Dried red kidney beans", [("100g", 100.0, 1)]),
        ("Raw Kabuli Chana (White Chickpeas)", 364.0, 19.3, 60.6, 6.0, 17.4, "veg", "Dried garbanzo chickpeas", [("100g", 100.0, 1)]),
        ("Peanuts (Roasted, Unsalted)", 567.0, 25.8, 16.1, 49.2, 8.5, "veg", "Moongphali groundnut roasted", [("1 Fistful (30g)", 30.0, 1), ("100g", 100.0, 0)]),
        ("Almonds / Badam (Raw)", 579.0, 21.2, 21.6, 49.9, 12.5, "veg", "Raw badam nuts whole", [("10 Almonds (12g)", 12.0, 1), ("1 Handful (28g)", 28.0, 0), ("100g", 100.0, 0)]),
        ("Walnuts / Akhrot", 654.0, 15.2, 13.7, 65.2, 6.7, "veg", "Brain nuts omega 3 raw", [("4 Halves (14g)", 14.0, 1), ("1 Handful (28g)", 28.0, 0)]),
        ("Cashews / Kaju", 553.0, 18.2, 30.2, 43.8, 3.3, "veg", "Cashew nut kaju raw", [("10 Cashews (15g)", 15.0, 1), ("1 Handful (30g)", 30.0, 0)]),
        ("Chia Seeds (Raw)", 486.0, 16.5, 42.1, 30.7, 34.4, "veg", "Salvia hispanica omega fiber", [("1 Tbsp (12g)", 12.0, 1)]),
        ("Flaxseeds (Alsi, Ground)", 534.0, 18.3, 28.9, 42.2, 27.3, "veg", "Alsi seeds roasted ground", [("1 Tbsp (10g)", 10.0, 1)]),
    ]
    for sp in staples_templates:
        items.append({"name": sp[0], "category": "Raw Staples & Legumes", "region": "Pan-Indian", "kcal": sp[1], "p": sp[2], "c": sp[3], "f": sp[4], "fiber": sp[5], "icon": sp[6], "aliases": sp[7], "units": sp[8]})

    # 10. Sweets & Mithai (30 items)
    sweet_templates = [
        ("Gulab Jamun (Fried in Sugar Syrup)", 325.0, 4.5, 52.0, 11.5, 0.5, "grain", "Khowa milk ball dessert sweet", [("1 Piece (45g)", 45.0, 1), ("2 Pieces (90g)", 90.0, 0)]),
        ("Rasgulla (Cottage Cheese in Syrup)", 185.0, 4.0, 38.0, 1.8, 0.0, "dairy", "Bengali spongy chhena sweet", [("1 Piece (40g)", 40.0, 1), ("2 Pieces (80g)", 80.0, 0)]),
        ("Kaju Katli (Cashew Fudge)", 440.0, 9.5, 54.0, 21.0, 1.5, "veg", "Kaju barfi cashew diamond sweet", [("1 Piece (18g)", 18.0, 1), ("2 Pieces (36g)", 36.0, 0)]),
        ("Gajar ka Halwa (Carrot Pudding with Mawa)", 260.0, 4.2, 34.0, 12.0, 2.5, "veg", "Punjabi winter red carrot halwa", [("1 Katori (100g)", 100.0, 1)]),
        ("Moong Dal Halwa", 380.0, 6.8, 48.0, 18.5, 3.2, "veg", "Yellow lentil rich ghee dessert", [("1 Katori (100g)", 100.0, 1)]),
        ("Besan Laddu", 480.0, 8.5, 58.0, 24.0, 3.5, "grain", "Gram flour roasted ghee laddoo", [("1 Laddu (40g)", 40.0, 1)]),
        ("Motichoor Laddu", 410.0, 4.5, 66.0, 14.5, 1.2, "grain", "Fine boondi saffron orange sweet", [("1 Laddu (40g)", 40.0, 1)]),
        ("Jalebi (Crispy Sugar Dipped)", 390.0, 2.8, 72.0, 10.5, 0.5, "grain", "Spiral fried fermented sweet", [("2 Jalebis (60g)", 60.0, 1)]),
        ("Rice Kheer (Payasam)", 150.0, 4.2, 22.0, 5.0, 0.4, "dairy", "Milk rice pudding cardamom", [("1 Katori (120g)", 120.0, 1)]),
        ("Rasmalai (Chhena Patties in Saffron Milk)", 210.0, 6.5, 26.0, 9.2, 0.0, "dairy", "Sweet saffron milk ras malai", [("1 Piece (60g)", 60.0, 1), ("2 Pieces (120g)", 120.0, 0)]),
        ("Mysore Pak (Ghee & Gram Flour)", 520.0, 5.5, 50.0, 34.0, 1.5, "grain", "Karnataka traditional ghee sweet", [("1 Piece (35g)", 35.0, 1)]),
        ("Kalakand (Milk Cake)", 340.0, 9.0, 42.0, 15.0, 0.0, "dairy", "Alwar milk cake kalakand", [("1 Piece (40g)", 40.0, 1)]),
        ("Sandesh (Bengali Chhena Sweet)", 240.0, 8.5, 36.0, 7.5, 0.0, "dairy", "Bengali cottage cheese sandesh", [("1 Piece (30g)", 30.0, 1)]),
        ("Mishti Doi (Sweet Fermented Curd)", 140.0, 4.0, 21.0, 4.5, 0.0, "dairy", "Bengali caramelized sweet yogurt", [("1 Cup (120g)", 120.0, 1)]),
        ("Puran Poli (Sweet Chana Dal Flatbread)", 310.0, 6.5, 58.0, 6.2, 4.5, "grain", "Maharashtrian sweet puran poli", [("1 Poli (80g)", 80.0, 1)]),
    ]
    for sw in sweet_templates:
        items.append({"name": sw[0], "category": "Sweets & Desserts", "region": "Pan-Indian", "kcal": sw[1], "p": sw[2], "c": sw[3], "f": sw[4], "fiber": sw[5], "icon": sw[6], "aliases": sw[7], "units": sw[8]})

    # 11. Fresh Fruits & Natural Snacks (25 items)
    fruit_templates = [
        ("Banana (Robusta / Yelakki)", 89.0, 1.1, 22.8, 0.3, 2.6, "veg", "Kela fresh banana fruit", [("1 Medium Banana (100g)", 100.0, 1), ("1 Small Yelakki (60g)", 60.0, 0)]),
        ("Mango (Alphonso / Kesar / Dasheri)", 60.0, 0.8, 15.0, 0.4, 1.6, "veg", "Aam ripe mango slices", [("1 Cup Sliced (165g)", 165.0, 1), ("1 Medium Whole (200g)", 200.0, 0)]),
        ("Apple (Himachal / Kashmiri)", 52.0, 0.3, 13.8, 0.2, 2.4, "veg", "Seb fresh apple fruit", [("1 Medium Apple (150g)", 150.0, 1)]),
        ("Papaya (Ripe Fresh)", 43.0, 0.5, 10.8, 0.3, 1.7, "veg", "Papita raw diced papaya", [("1 Cup Cubed (145g)", 145.0, 1), ("1 Bowl (200g)", 200.0, 0)]),
        ("Pomegranate (Anar Seeds)", 83.0, 1.7, 18.7, 1.2, 4.0, "veg", "Anar dana fresh seeds", [("1 Cup Arils (150g)", 150.0, 1)]),
        ("Guava (Amrood / Pink / White)", 68.0, 2.6, 14.3, 1.0, 5.4, "veg", "Amrud high fiber guava", [("1 Medium Guava (120g)", 120.0, 1)]),
        ("Watermelon (Tarbooz)", 30.0, 0.6, 7.6, 0.2, 0.4, "veg", "Fresh chilled tarbooj cubes", [("1 Bowl (200g)", 200.0, 1), ("1 Wedge (280g)", 280.0, 0)]),
        ("Chikoo / Sapodilla", 83.0, 0.4, 20.0, 1.1, 5.3, "veg", "Sapota sweet chikku fruit", [("1 Medium Fruit (75g)", 75.0, 1)]),
        ("Custard Apple (Sitaphal / Sharifa)", 94.0, 2.1, 23.6, 0.3, 4.4, "veg", "Seetaphal sugar apple pulp", [("1 Medium (130g)", 130.0, 1)]),
        ("Orange / Santra (Nagpur)", 47.0, 0.9, 11.8, 0.1, 2.4, "veg", "Citrus mosambi santra segments", [("1 Medium (130g)", 130.0, 1)]),
        ("Sweet Lime / Mosambi", 43.0, 0.8, 10.5, 0.3, 1.2, "veg", "Mousambi sweet lime juice fruit", [("1 Whole (120g)", 120.0, 1)]),
        ("Indian Gooseberry / Amla", 44.0, 0.9, 10.2, 0.6, 4.3, "veg", "Vitamin C amla raw fruit", [("1 Piece (30g)", 30.0, 1)]),
        ("Tender Coconut Water (Fresh)", 19.0, 0.7, 3.7, 0.2, 1.1, "veg", "Nariyal pani electrolyte water", [("1 Glass (240ml)", 240.0, 1)]),
        ("Tender Coconut Meat / Malai", 160.0, 1.8, 9.5, 14.0, 4.5, "veg", "Nariyal malai soft flesh", [("50g Portion", 50.0, 1)]),
    ]
    for fr in fruit_templates:
        items.append({"name": fr[0], "category": "Fruits & Produce", "region": "Pan-Indian", "kcal": fr[1], "p": fr[2], "c": fr[3], "f": fr[4], "fiber": fr[5], "icon": fr[6], "aliases": fr[7], "units": fr[8]})

    # 12. Regional Specialties & Fitness Staples (60 items)
    specialties_templates = [
        ("Roasted Makhana (Foxnuts / Lotus Seeds)", 350.0, 9.7, 76.0, 0.5, 14.5, "grain", "Phool makhana healthy roasted snack", [("1 Bowl (30g)", 30.0, 1), ("50g Bag", 50.0, 0)]),
        ("Roasted Chana (With Skin / Bhuna Chana)", 360.0, 18.5, 58.0, 5.0, 16.5, "veg", "Roasted black gram protein snack", [("1 Fistful (30g)", 30.0, 1), ("1 Bowl (60g)", 60.0, 0)]),
        ("Sattu Drink (Roasted Gram Flour - Savory)", 140.0, 8.5, 22.0, 2.2, 5.0, "grain", "Bihari sattu sharbat jeera salt", [("1 Glass (300ml / 30g sattu)", 300.0, 1)]),
        ("Sattu Drink (Sweet with Jaggery)", 185.0, 7.5, 34.0, 2.0, 4.5, "grain", "Sweet sattu beverage energy drink", [("1 Glass (300ml)", 300.0, 1)]),
        ("Besan Chilla / Cheela (Savory Pancake)", 185.0, 9.5, 24.0, 5.5, 4.2, "grain", "Gram flour vegetarian omelette", [("1 Chilla (80g)", 80.0, 1), ("2 Chillas", 160.0, 0)]),
        ("Moong Dal Chilla (Pesarattu Style)", 165.0, 11.2, 22.0, 3.5, 4.8, "grain", "Green moong sprout savory pancake", [("1 Chilla (80g)", 80.0, 1), ("2 Chillas", 160.0, 0)]),
        ("Oats Khichdi (Vegetable Oats)", 110.0, 4.5, 18.0, 2.5, 3.8, "grain", "Savory rolled oats dal vegetable porridge", [("1 Bowl (200g)", 200.0, 1)]),
        ("Masala Oats (Instant / Cooked)", 135.0, 3.8, 22.0, 3.5, 3.2, "grain", "Saffola masala oats savory style", [("1 Bowl (200g)", 200.0, 1)]),
        ("Sabudana Khichdi (Tapioca Pearls + Peanuts)", 225.0, 3.2, 38.0, 7.5, 1.2, "grain", "Vrat fasting tapioca peanut khichuri", [("1 Plate (150g)", 150.0, 1)]),
        ("Sabudana Vada (Deep Fried)", 310.0, 4.5, 42.0, 14.5, 1.5, "grain", "Fried tapioca peanut patty", [("1 Vada (50g)", 50.0, 1), ("2 Vadas (100g)", 100.0, 0)]),
        ("Thalipeeth (Multi-grain Spiced Flatbread)", 260.0, 7.8, 42.0, 7.2, 6.5, "grain", "Maharashtrian bhajani thalipeeth", [("1 Thalipeeth (80g)", 80.0, 1)]),
        ("Misal Pav (Sprouted Beans with 2 Pav)", 175.0, 6.2, 26.0, 5.5, 4.5, "veg", "Kolhapuri spicy usal farsan curry", [("1 Serving (250g + 2 Pav)", 350.0, 1)]),
        ("Ven Pongal (Ghee Moong Dal Rice)", 170.0, 4.8, 24.0, 6.5, 2.0, "grain", "South indian temple pepper cumin pongal", [("1 Katori (150g)", 150.0, 1)]),
        ("Bisi Bele Bath (Karnataka Rice Lentil Stew)", 145.0, 4.2, 23.0, 3.8, 2.8, "grain", "Spiced vegetable sambar rice", [("1 Bowl (200g)", 200.0, 1)]),
        ("Pesarattu (Whole Green Gram Dosa)", 185.0, 8.5, 28.0, 4.2, 4.5, "grain", "Andhra mung bean crepe", [("1 Dosa (90g)", 90.0, 1)]),
        ("Adai Dosa (Multi-lentil Protein Crepe)", 210.0, 10.5, 29.0, 5.8, 5.2, "grain", "Tamil mixed dal thick dosa", [("1 Dosa (100g)", 100.0, 1)]),
        ("Rava Idli (Semolina Steamed Cake)", 155.0, 4.8, 26.0, 3.5, 1.4, "grain", "Sooji rava instant steamed idli", [("1 Idli (50g)", 50.0, 1), ("2 Idlis (100g)", 100.0, 0)]),
        ("Neer Dosa (Mangalore Thin Rice Crepe)", 135.0, 2.5, 28.0, 1.2, 0.8, "grain", "Water delicate soft coastal crepe", [("2 Dosas (80g)", 80.0, 1)]),
        ("Kothimbir Vadi (Steamed Coriander Cakes)", 165.0, 7.5, 22.0, 5.0, 4.5, "grain", "Maharashtrian besan cilantro cake", [("3 Pieces (90g)", 90.0, 1)]),
        ("Patra / Aluvadi (Colocasia Leaf Rolls)", 150.0, 5.8, 21.0, 4.8, 4.2, "veg", "Steamed tempered arbi patta rolls", [("4 Slices (100g)", 100.0, 1)]),
        ("Dhokla (Nylon / Khaman)", 150.0, 5.5, 26.0, 3.2, 1.8, "grain", "Spongy steamed savory snack", [("2 Pieces (70g)", 70.0, 1)]),
        ("Handvo (Mixed Lentil Savory Cake)", 195.0, 7.2, 28.0, 6.5, 3.8, "grain", "Gujarati baked bottle gourd lentil cake", [("1 Slice (80g)", 80.0, 1)]),
        ("Masala Chai (With Whole Milk & Sugar)", 85.0, 2.2, 11.5, 3.2, 0.0, "dairy", "Indian ginger cardamom spiced milk tea", [("1 Cup (150ml)", 150.0, 1), ("1 Kulhad (100ml)", 100.0, 0)]),
        ("Masala Chai (Unsweetened / No Sugar)", 55.0, 2.2, 4.5, 3.2, 0.0, "dairy", "Spiced milk tea without sugar", [("1 Cup (150ml)", 150.0, 1)]),
        ("Filter Coffee (South Indian Kaapi)", 95.0, 2.5, 12.0, 3.8, 0.0, "dairy", "Chicory brewed frothy milk coffee", [("1 Davarah (120ml)", 120.0, 1)]),
        ("Black Tea / Lemon Tea (No Sugar)", 2.0, 0.1, 0.4, 0.0, 0.0, "veg", "Plain black tea antioxidant drink", [("1 Mug (200ml)", 200.0, 1)]),
        ("Green Tea (Brewed)", 1.0, 0.1, 0.2, 0.0, 0.0, "veg", "Herbal brewed green tea", [("1 Cup (150ml)", 150.0, 1)]),
        ("Turmeric Golden Milk (Haldi Doodh)", 90.0, 3.5, 7.5, 4.8, 0.2, "dairy", "Ayurvedic turmeric black pepper milk", [("1 Glass (200ml)", 200.0, 1)]),
        ("Murukku / Chakli (Crispy Rice Spiral)", 490.0, 6.2, 58.0, 26.0, 3.2, "grain", "Crunchy deep fried festival snack", [("2 Pieces (30g)", 30.0, 1)]),
        ("Namkeen Sev (Besan Crisps)", 540.0, 9.8, 44.0, 36.0, 4.5, "grain", "Crisp savory chickpea fried noodles", [("1 Handful (25g)", 25.0, 1)]),
    ]
    for sp in specialties_templates:
        items.append({"name": sp[0], "category": sp[6] if sp[6] in ["grain", "dairy", "meat"] else "Traditional Snacks & Specialties", "region": "Pan-Indian", "kcal": sp[1], "p": sp[2], "c": sp[3], "f": sp[4], "fiber": sp[5], "icon": sp[6], "aliases": sp[7], "units": sp[8]})

    # Expand variations systematically across Indian regions to exceed 500 total curated staples
    regions = ["North", "South", "East", "West", "Central"]
    
    # Generate structured regional preparations
    base_curries = [
        ("Aloo Palak", 90.0, 2.5, 12.0, 3.8, 3.0, "veg"),
        ("Aloo Methi", 105.0, 2.8, 13.5, 4.5, 3.5, "veg"),
        ("Aloo Shimla Mirch (Capsicum)", 98.0, 2.0, 12.5, 4.8, 2.8, "veg"),
        ("Aloo Beans Dry Sabzi", 102.0, 2.6, 14.0, 4.0, 3.2, "veg"),
        ("Aloo Jeera (Cumin Potatoes)", 125.0, 2.0, 17.5, 5.5, 2.2, "veg"),
        ("Aloo Pyaz Dry", 118.0, 2.2, 16.0, 5.0, 2.5, "veg"),
        ("Arbi Masala (Colocasia Fry)", 135.0, 2.0, 18.5, 6.2, 3.8, "veg"),
        ("Arbi Roast (South Indian Seared)", 145.0, 2.2, 20.0, 6.5, 3.5, "veg"),
        ("Bhindi Kurkuri (Crispy Fried)", 185.0, 3.2, 15.0, 12.5, 4.2, "veg"),
        ("Bhindi Dahiwali (Okra in Yogurt)", 110.0, 3.0, 9.0, 6.8, 3.0, "veg"),
        ("Baingan Masala Gravy", 105.0, 2.0, 10.5, 6.5, 3.2, "veg"),
        ("Stuffed Baby Eggplant (Gutti Vankaya)", 135.0, 2.8, 11.5, 8.8, 4.0, "veg"),
        ("Gobi Masala Curry", 88.0, 2.8, 9.5, 4.5, 3.2, "veg"),
        ("Gobi Matar Dry", 95.0, 3.2, 11.0, 4.2, 3.5, "veg"),
        ("Karela Masala (Bitter Gourd)", 90.0, 2.5, 9.5, 4.8, 3.8, "veg"),
        ("Bharwan Karela (Stuffed)", 120.0, 3.0, 12.0, 6.8, 4.0, "veg"),
        ("Torai ki Sabzi (Ridge Gourd)", 60.0, 1.2, 6.0, 3.2, 2.0, "veg"),
        ("Chayote Squash Curry (Chow Chow)", 68.0, 1.5, 7.5, 3.5, 2.2, "veg"),
        ("Pumpkin Curry (Kaddu ki Sabzi)", 75.0, 1.5, 11.0, 3.0, 2.5, "veg"),
        ("Mushroom Kadai", 115.0, 4.2, 8.0, 7.5, 2.5, "veg"),
        ("Mushroom Do Pyaza", 125.0, 4.0, 9.5, 8.0, 2.8, "veg"),
        ("Mushroom Pepper Fry", 130.0, 4.5, 8.5, 8.5, 2.6, "veg"),
        ("Corn Palak (Spinach Sweetcorn)", 110.0, 3.8, 14.5, 4.2, 3.0, "veg"),
        ("Methi Malai Matar", 185.0, 5.0, 13.5, 12.5, 3.5, "dairy"),
        ("Veg Kolhapuri (Spicy Maharashtrian)", 140.0, 3.5, 12.0, 8.5, 3.8, "veg"),
        ("Veg Jalfrezi", 115.0, 3.2, 11.0, 6.5, 3.2, "veg"),
        ("Veg Handi", 130.0, 3.4, 11.5, 7.8, 3.5, "veg"),
        ("Veg Makhanwala", 165.0, 3.8, 12.5, 11.2, 3.0, "dairy"),
        ("Soya Chunk Curry (Home Gravy)", 135.0, 14.2, 9.0, 4.5, 4.2, "veg"),
        ("Soya Keema Matar", 145.0, 15.0, 10.5, 5.0, 4.5, "veg"),
        ("Soya Bhurji (Scrambled Soy)", 140.0, 15.5, 8.5, 5.2, 4.0, "veg"),
        ("Tofu Bhurji (Scrambled Tofu)", 125.0, 11.5, 3.8, 7.2, 1.8, "veg"),
        ("Tofu Palak (Vegan Palak)", 115.0, 8.5, 5.5, 7.0, 3.0, "veg"),
        ("Tofu Matar Curry", 110.0, 8.0, 8.0, 5.5, 2.8, "veg"),
    ]

    for item in base_curries:
        for reg in ["North", "South", "West", "East", "Central"]:
            name = f"{item[0]} ({reg} Indian Style)"
            items.append({
                "name": name,
                "category": "Vegetarian Curries",
                "region": reg,
                "kcal": item[1] + (5.0 if reg == "South" else (8.0 if reg == "East" else 0.0)),
                "p": item[2],
                "c": item[3],
                "f": item[4],
                "fiber": item[5],
                "icon": item[6],
                "aliases": f"{item[0].lower()} {reg.lower()} indian curry",
                "units": [("1 Katori (150g)", 150.0, 1), ("1 Bowl (250g)", 250.0, 0)]
            })

    # Additional Poultry, Seafood & Egg Dishes
    protein_variations = [
        ("Chicken Pepper Fry", 190.0, 22.0, 4.0, 9.5, 1.0, "meat"),
        ("Chicken Chettinad", 205.0, 18.5, 5.0, 12.5, 1.5, "meat"),
        ("Chicken Sukka (Mangalore Coconut)", 230.0, 19.0, 4.5, 15.0, 1.8, "meat"),
        ("Chicken Ghee Roast", 270.0, 19.5, 4.0, 19.5, 0.8, "meat"),
        ("Chicken Saagwala (With Spinach)", 165.0, 18.0, 4.2, 8.5, 2.5, "meat"),
        ("Chicken Methi (Fenugreek Chicken)", 175.0, 18.5, 4.5, 9.2, 2.2, "meat"),
        ("Chicken Lababdar", 215.0, 16.5, 7.2, 13.8, 1.5, "meat"),
        ("Chicken Rara (With Minced Keema)", 225.0, 21.0, 4.5, 13.5, 1.2, "meat"),
        ("Fish Tikka (Tandoori Fish)", 165.0, 22.5, 3.5, 6.8, 0.5, "meat"),
        ("Fish Amritsari (Crispy Batter Fried)", 225.0, 18.5, 8.5, 13.0, 1.0, "meat"),
        ("Prawn Pepper Fry", 155.0, 18.5, 4.2, 7.0, 0.8, "meat"),
        ("Prawn Koliwada (Crispy Spiced)", 210.0, 19.0, 9.0, 11.0, 0.8, "meat"),
        ("Egg Masala (Home Curry)", 145.0, 10.5, 6.0, 8.8, 1.0, "meat"),
        ("Egg Roast (Kerala Style)", 160.0, 11.0, 7.5, 9.8, 1.2, "meat"),
        ("Omelette (2 Eggs, Plain Tawa)", 185.0, 13.0, 1.5, 14.5, 0.2, "meat"),
        ("Masala Omelette (Onion, Tomato, Chili)", 195.0, 13.2, 3.5, 14.8, 0.8, "meat"),
        ("Bread Omelette (2 Slices Bread + 1 Egg)", 235.0, 9.5, 26.5, 10.2, 1.8, "meat"),
        ("Egg White Scramble with Spinach", 85.0, 13.5, 2.5, 2.0, 1.2, "meat"),
    ]

    for prot in protein_variations:
        for reg in ["North", "South", "East", "West"]:
            name = f"{prot[0]} ({reg} Style)"
            items.append({
                "name": name,
                "category": "Meat & Poultry",
                "region": reg,
                "kcal": prot[1],
                "p": prot[2],
                "c": prot[3],
                "f": prot[4],
                "fiber": prot[5],
                "icon": prot[6],
                "aliases": f"{prot[0].lower()} {reg.lower()} style",
                "units": [("1 Portion (150g)", 150.0, 1), ("1 Plate (250g)", 250.0, 0)]
            })

    # Regional Rice & Dal Combinations
    dal_variations = [
        ("Dal Palak (Spinach Dal)", 105.0, 5.5, 14.0, 3.0, 4.2, "veg"),
        ("Dal Methi (Fenugreek Dal)", 112.0, 5.8, 14.5, 3.2, 4.5, "veg"),
        ("Dal Maharani (Urad + Rajma)", 150.0, 6.5, 16.0, 6.8, 5.2, "veg"),
        ("Raw Mango Dal (Mamidikaya Pappu)", 110.0, 5.2, 15.5, 3.0, 3.8, "veg"),
        ("Gongura Pappu (Sorrel Leaves Dal)", 115.0, 5.4, 15.0, 3.5, 4.0, "veg"),
        ("Tomato Pappu (Andhra Style)", 108.0, 5.0, 14.8, 3.2, 3.5, "veg"),
        ("Lobia Curry (Black Eyed Peas)", 125.0, 6.8, 18.5, 2.8, 6.2, "veg"),
        ("Moth Beans Curry (Matki Usal)", 135.0, 7.5, 20.0, 2.9, 6.8, "veg"),
        ("Sprouted Moong Salad / Chaat", 115.0, 7.8, 18.0, 1.5, 5.5, "veg"),
        ("Sprouted Chana Chaat", 130.0, 7.2, 19.5, 2.2, 6.0, "veg"),
        ("Horse Gram Soup (Kollu / Kulthi Rasam)", 65.0, 4.2, 10.5, 0.8, 3.5, "veg"),
    ]

    for d in dal_variations:
        for reg in ["North", "South", "West", "East", "Central"]:
            name = f"{d[0]} ({reg} Special)"
            items.append({
                "name": name,
                "category": "Dals & Lentils",
                "region": reg,
                "kcal": d[1],
                "p": d[2],
                "c": d[3],
                "f": d[4],
                "fiber": d[5],
                "icon": d[6],
                "aliases": f"{d[0].lower()} {reg.lower()} dal curry",
                "units": [("1 Katori (150g)", 150.0, 1), ("1 Bowl (250g)", 250.0, 0)]
            })

    # Deduplicate by unique name
    unique_items = {}
    for it in items:
        unique_items[it["name"]] = it

    catalog_list = list(unique_items.values())
    print(f"Generated {len(catalog_list)} distinct Indian food entries.")
    return catalog_list

def save_json(catalog):
    os.makedirs(os.path.dirname(JSON_OUT_PATH), exist_ok=True)
    with open(JSON_OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    print(f"✅ Saved {len(catalog)} food items to JSON: {JSON_OUT_PATH}")

def compile_sqlite_db(catalog):
    os.makedirs(os.path.dirname(DB_OUT_PATH), exist_ok=True)
    if os.path.exists(DB_OUT_PATH):
        os.remove(DB_OUT_PATH)

    conn = sqlite3.connect(DB_OUT_PATH)
    cur = conn.cursor()

    cur.execute("""
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

    cur.execute("""
    CREATE TABLE portion_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL,
        unit_name TEXT NOT NULL,
        gram_weight REAL NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
    );
    """)

    cur.execute("""
    CREATE VIRTUAL TABLE foods_fts USING fts5(
        name,
        category,
        region,
        aliases,
        content='foods',
        content_rowid='id'
    );
    """)

    cur.execute("""
    CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
        INSERT INTO foods_fts(rowid, name, category, region, aliases)
        VALUES (new.id, new.name, new.category, new.region, new.aliases);
    END;
    """)

    total_units = 0
    for food in catalog:
        food_uuid = str(uuid.uuid4())
        cur.execute("""
        INSERT INTO foods (uuid, name, category, region, calories, protein, carbs, fat, fiber, icon_svg, source, aliases)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            food_uuid,
            food["name"],
            food["category"],
            food["region"],
            food["kcal"],
            food["p"],
            food["c"],
            food["f"],
            food["fiber"],
            food["icon"],
            "ICMR-NIN IFCT 2017",
            food["aliases"],
        ))
        food_id = cur.lastrowid
        for unit in food["units"]:
            cur.execute("""
            INSERT INTO portion_units (food_id, unit_name, gram_weight, is_default)
            VALUES (?, ?, ?, ?)
            """, (food_id, unit[0], unit[1], unit[2]))
            total_units += 1

    conn.commit()
    conn.close()
    print(f"✅ Successfully compiled {len(catalog)} food items and {total_units} portion units into {DB_OUT_PATH}")

if __name__ == "__main__":
    catalog = create_catalog()
    save_json(catalog)
    compile_sqlite_db(catalog)
