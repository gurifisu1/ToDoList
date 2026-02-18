-- Supabase Schema for ToDo App
-- Run this in Supabase SQL Editor to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Tables
-- ============================================

-- Tags table
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#6C63FF',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ,
  estimated_minutes INT,
  priority INT NOT NULL DEFAULT 0, -- 0: none, 1: low, 2: medium, 3: high
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  sort_order INT NOT NULL DEFAULT 0,
  reminder_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Task-Tag junction table
CREATE TABLE IF NOT EXISTS task_tags (
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (task_id, tag_id)
);

-- Subtasks table
CREATE TABLE IF NOT EXISTS subtasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  due_date TIMESTAMPTZ,
  priority INT NOT NULL DEFAULT 0,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Subtask-Tag junction table
CREATE TABLE IF NOT EXISTS subtask_tags (
  subtask_id UUID NOT NULL REFERENCES subtasks(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (subtask_id, tag_id)
);

-- ============================================
-- Row Level Security (RLS)
-- ============================================

ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtask_tags ENABLE ROW LEVEL SECURITY;

-- Tags policies
CREATE POLICY "Users can view their own tags" ON tags
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own tags" ON tags
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own tags" ON tags
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own tags" ON tags
  FOR DELETE USING (auth.uid() = user_id);

-- Tasks policies
CREATE POLICY "Users can view their own tasks" ON tasks
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own tasks" ON tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own tasks" ON tasks
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own tasks" ON tasks
  FOR DELETE USING (auth.uid() = user_id);

-- Task_tags policies
CREATE POLICY "Users can view their own task_tags" ON task_tags
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM tasks WHERE tasks.id = task_tags.task_id AND tasks.user_id = auth.uid())
  );
CREATE POLICY "Users can insert their own task_tags" ON task_tags
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM tasks WHERE tasks.id = task_tags.task_id AND tasks.user_id = auth.uid())
  );
CREATE POLICY "Users can delete their own task_tags" ON task_tags
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM tasks WHERE tasks.id = task_tags.task_id AND tasks.user_id = auth.uid())
  );

-- Subtasks policies
CREATE POLICY "Users can view their own subtasks" ON subtasks
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own subtasks" ON subtasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own subtasks" ON subtasks
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own subtasks" ON subtasks
  FOR DELETE USING (auth.uid() = user_id);

-- Subtask_tags policies
CREATE POLICY "Users can view their own subtask_tags" ON subtask_tags
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM subtasks WHERE subtasks.id = subtask_tags.subtask_id AND subtasks.user_id = auth.uid())
  );
CREATE POLICY "Users can insert their own subtask_tags" ON subtask_tags
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM subtasks WHERE subtasks.id = subtask_tags.subtask_id AND subtasks.user_id = auth.uid())
  );
CREATE POLICY "Users can delete their own subtask_tags" ON subtask_tags
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM subtasks WHERE subtasks.id = subtask_tags.subtask_id AND subtasks.user_id = auth.uid())
  );

-- ============================================
-- Updated_at triggers
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tags_updated_at
  BEFORE UPDATE ON tags
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subtasks_updated_at
  BEFORE UPDATE ON subtasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Realtime subscriptions
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE subtasks;
ALTER PUBLICATION supabase_realtime ADD TABLE tags;
ALTER PUBLICATION supabase_realtime ADD TABLE task_tags;
ALTER PUBLICATION supabase_realtime ADD TABLE subtask_tags;

-- ============================================
-- Indexes
-- ============================================

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_sort_order ON tasks(sort_order);
CREATE INDEX idx_subtasks_task_id ON subtasks(task_id);
CREATE INDEX idx_subtasks_user_id ON subtasks(user_id);
CREATE INDEX idx_tags_user_id ON tags(user_id);
