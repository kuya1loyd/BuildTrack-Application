const String kSchemaSql = '''
create table if not exists buildtrack_users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null unique,
  password_hash text not null,
  company text not null default '',
  phone text not null default '',
  role text not null default 'Project Manager',
  created_at timestamptz not null default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  name text not null,
  location text not null default '',
  client text not null default '',
  status text not null default 'active',
  progress integer not null default 0 check (progress between 0 and 100),
  start_date date,
  end_date date,
  budget numeric not null default 0,
  spent numeric not null default 0,
  phase text not null default '',
  members integer not null default 0,
  current_stage text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists projects_user_idx on projects(user_id);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  title text not null,
  team text not null default '',
  due_date date,
  due_time text not null default '',
  status text not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists tasks_user_idx on tasks(user_id);
create index if not exists tasks_project_idx on tasks(project_id);

create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  name text not null,
  category text not null default '',
  quantity numeric not null default 0,
  unit text not null default '',
  status text not null default 'available',
  icon text not null default 'cube',
  created_at timestamptz not null default now()
);
create index if not exists materials_user_idx on materials(user_id);

create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  name text not null,
  role text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists team_user_idx on team_members(user_id);

create table if not exists timeline_steps (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  name text not null,
  position integer not null default 0,
  status text not null default 'pending',
  unique (project_id, position)
);
''';
