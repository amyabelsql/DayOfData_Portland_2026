-- Creates the DemoShop database if it isn't there yet. Safe to run twice.
IF DB_ID(N'DemoShop') IS NULL
    CREATE DATABASE DemoShop;
GO
