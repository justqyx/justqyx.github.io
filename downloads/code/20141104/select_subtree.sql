-- 创建获取子节点的函数
CREATE OR REPLACE FUNCTION collect_childs_func(dept_id INTEGER, ancestry CHARACTER VARYING(255)) RETURNS TEXT AS $$
DECLARE
  -- 初始化变量
  child_ancestry CHARACTER VARYING(255);
  dept RECORD;
  children TEXT;
  childs TEXT[] = '{}';
BEGIN
  -- 得到查子节点的 ancestry 变量
  IF ancestry IS NULL THEN
    child_ancestry := dept_id;
  ELSE
    child_ancestry := (ancestry || '/' || dept_id);
  END IF;

  -- 查询其子部门
  FOR dept IN SELECT * FROM departments WHERE departments.ancestry = child_ancestry ORDER BY departments.id LOOP
    IF dept.ancestry IS NULL THEN
      childs := ARRAY_APPEND(childs, '{ "id": ' || dept.id || ', "name": "' || dept.name || '", "children": []}');
    ELSE
      childs := ARRAY_APPEND(childs, '{ "id": ' || dept.id || ', "name": "' || dept.name || '", "children":' || collect_childs_func(dept.id, dept.ancestry) || '}');
    END IF;
  END LOOP;

  children := ARRAY_TO_STRING(childs, ',');
  children := '[' || children || ']';

  RETURN children;
END;
$$ LANGUAGE plpgsql
