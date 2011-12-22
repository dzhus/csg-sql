module CSG

where

import Database.HDBC
import Database.HDBC.PostgreSQL

-- * CSG types
type Vector = (Double, Double, Double)
type Point = Vector

-- Basic geometrical object
data Object = Sphere Point Double
            | Plane Vector Double
            | Cylinder Vector Point Double
            deriving Show

-- Composition of objects
data Body = Primitive Object
          | Union [Body]
          | Intersection [Body]
          | Complement Body
          deriving Show

-- * SQL interface

-- PostgreSQL connection options
dbOpts = "host=195.19.32.74 port=5432 dbname=dbAK3_111_Volkova user=ddzhus password=p3py4k@"

parentId :: (Maybe SqlValue) -> SqlValue
parentId Nothing = SqlNull
parentId (Just i) = i

composeType :: Body -> SqlValue
composeType (Primitive _) = toSql (0::Integer)
composeType (Complement _) = toSql (1::Integer)
composeType (Union _) = toSql (2::Integer)
composeType (Intersection _) = toSql (3::Integer)

getCurrVal :: [[SqlValue]] -> SqlValue
getCurrVal [[v]] = v

-- Save body and possibly recurse into its members
saveBody :: IConnection c => c -> Body -> (Maybe SqlValue) -> IO SqlValue
saveBody conn b parent = do
  run conn 
          "INSERT INTO ddv.bodies (compose_type, parent_body_id) VALUES (?, ?);"
          [composeType b, parentId parent]
  res <- quickQuery' conn 
         "SELECT currval('ddv.body_seq');" []
  let
      pid = Just (getCurrVal res)
   in
     do
       case b of
         (Primitive o) -> do saveObject conn o (getCurrVal res)
                             return SqlNull
         (Complement b) -> saveBody conn b pid
         (Union members) -> do mapM_ (\m -> saveBody conn m pid) members
                               return SqlNull
         (Intersection members) -> do mapM_ (\m -> saveBody conn m pid) members
                                      return SqlNull
  commit conn
  return (getCurrVal res)

-- Mapping object types to values of object_type field
objectType :: Object -> SqlValue
objectType (Plane _ _) = toSql (0::Integer)
objectType (Sphere _ _) = toSql (1::Integer)
objectType (Cylinder _ _ _) = toSql (2::Integer)

-- Save object and recurse into saving its parameters
saveObject :: IConnection c => c -> Object -> SqlValue -> IO ()
saveObject conn obj parent = do
  run conn
          "INSERT INTO ddv.objects (object_type, parent_primitive_id) VALUES (?, ?);"
          [objectType obj, parent]
  res <- quickQuery' conn
         "SELECT currval('ddv.object_seq');" []
  let
      pid = getCurrVal res
   in
     do
       case obj of
         (Plane v d) -> do saveVector conn v 0 pid
                           saveScalar conn d 1 pid
         (Sphere c r) -> do saveVector conn c 0 pid
                            saveScalar conn r 1 pid
         (Cylinder v p d) -> do saveVector conn v 0 pid
                                saveVector conn p 1 pid
                                saveScalar conn d 2 pid
  commit conn

parameterQuery = "INSERT INTO ddv.parameters (parent_object_id, dim, parameter_pos) VALUES (?, ?, ?);"

-- Save vector parameter and recurse into saving its components
saveVector :: IConnection c => c -> Vector -> Integer -> SqlValue -> IO ()
saveVector conn v@(x, y, z) pos parent = do
  run conn parameterQuery [parent, toSql (3::Integer), toSql pos]
  res <- quickQuery' conn
         "SELECT currval('ddv.parameter_seq');" []
  let 
      pid = getCurrVal res
   in
     do
       saveValue conn x 0 pid
       saveValue conn y 1 pid
       saveValue conn z 2 pid
  commit conn

-- Save scalar parameter and recurse into saving its value
saveScalar :: IConnection c => c -> Double -> Integer -> SqlValue -> IO ()
saveScalar conn s pos parent = do
  run conn parameterQuery [parent, toSql (1::Integer), toSql pos]
  res <- quickQuery' conn
         "SELECT currval('ddv.parameter_seq');" []  
  saveValue conn s 0 (getCurrVal res)
  commit conn

-- Save value of parameter
saveValue :: IConnection c => c -> Double -> Integer -> SqlValue -> IO ()
saveValue conn value pos parent = do
  run conn
      "INSERT INTO ddv.values (parent_parameter_id, val, value_pos) VALUES (?, ?, ?);"
      [parent, toSql value, toSql pos]
  quickQuery' conn "SELECT currval('ddv.value_seq');" []  
  commit conn
