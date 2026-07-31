-- ProgressOS Supabase Database Schema
-- Run this script in your Supabase SQL Editor to initialize the database tables, indexes, and RLS policies.

-- Enable UUID extension
create extension if not exists "uuid-ossp";

---------------------------------------------------------
-- PROFILES TABLE
---------------------------------------------------------
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text not null,
    name text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Policies for profiles
create policy "Users can view their own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can insert their own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

create policy "Users can update their own profile"
    on public.profiles for update
    using (auth.uid() = id);

---------------------------------------------------------
-- TASKS TABLE
---------------------------------------------------------
create table public.tasks (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users on delete cascade not null,
    title text not null,
    description text,
    priority text default 'Medium'::text not null, -- 'Low', 'Medium', 'High'
    status text default 'Pending'::text not null,  -- 'Pending', 'Completed'
    category text default 'General'::text not null, -- 'Study', 'Coding', 'Health', 'Meeting', etc.
    date date not null,
    start_time text, -- Format: "HH:MM"
    end_time text,   -- Format: "HH:MM"
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.tasks enable row level security;

-- Policies for tasks
create policy "Users can view their own tasks"
    on public.tasks for select
    using (auth.uid() = user_id);

create policy "Users can insert their own tasks"
    on public.tasks for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own tasks"
    on public.tasks for update
    using (auth.uid() = user_id);

create policy "Users can delete their own tasks"
    on public.tasks for delete
    using (auth.uid() = user_id);

-- Indexes for performance optimization
create index tasks_user_id_idx on public.tasks(user_id);
create index tasks_date_idx on public.tasks(date);

---------------------------------------------------------
-- SCHEDULE TABLE
---------------------------------------------------------
create table public.schedule (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users on delete cascade not null,
    title text not null,
    date date not null,
    start_time text not null, -- Format: "HH:MM"
    end_time text not null,   -- Format: "HH:MM"
    note text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.schedule enable row level security;

-- Policies for schedule
create policy "Users can view their own schedule"
    on public.schedule for select
    using (auth.uid() = user_id);

create policy "Users can insert their own schedule"
    on public.schedule for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own schedule"
    on public.schedule for update
    using (auth.uid() = user_id);

create policy "Users can delete their own schedule"
    on public.schedule for delete
    using (auth.uid() = user_id);

-- Indexes for performance optimization
create index schedule_user_id_idx on public.schedule(user_id);
create index schedule_date_idx on public.schedule(date);
create index schedule_time_idx on public.schedule(start_time);
