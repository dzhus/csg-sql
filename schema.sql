CREATE DOMAIN ddv.body_id_t
   AS integer;

CREATE DOMAIN ddv.object_id_t
   AS integer;

CREATE DOMAIN ddv.parameter_id_t
   AS integer;

CREATE DOMAIN ddv.value_id_t
   AS integer;

CREATE DOMAIN ddv.compose_type_t
   AS smallint;

CREATE DOMAIN ddv.object_type_t
   AS smallint;

CREATE DOMAIN ddv.value_t
   AS real;

CREATE DOMAIN ddv.pos_t
   AS smallint;

CREATE DOMAIN ddv.dim_t
   AS smallint;

DROP SEQUENCE ddv.body_seq;
DROP SEQUENCE ddv.object_seq;
DROP SEQUENCE ddv.parameter_seq;
DROP SEQUENCE ddv.value_seq;

CREATE SEQUENCE ddv.body_seq;
CREATE SEQUENCE ddv.object_seq;
CREATE SEQUENCE ddv.parameter_seq;
CREATE SEQUENCE ddv.value_seq;

DROP TABLE ddv.values;
DROP TABLE ddv.parameters;
DROP TABLE ddv.objects;
DROP TABLE ddv.bodies;

CREATE TABLE ddv.bodies
(
  body_id ddv.body_id_t NOT NULL DEFAULT NEXTVAL('ddv.body_seq'),
  compose_type ddv.compose_type_t NOT NULL DEFAULT 0,
  parent_body_id ddv.body_id_t NULL,
  CONSTRAINT bodies_pkey PRIMARY KEY (body_id ),
  CONSTRAINT bodies_plink FOREIGN KEY (parent_body_id)
      REFERENCES ddv.bodies (body_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ddv.objects
(
  object_id ddv.object_id_t NOT NULL DEFAULT NEXTVAL('ddv.object_seq'),
  object_type ddv.object_type_t NOT NULL DEFAULT 0,
  parent_primitive_id ddv.body_id_t NOT NULL,
  CONSTRAINT objects_pkey PRIMARY KEY (object_id),
  CONSTRAINT objects_plink FOREIGN KEY (parent_primitive_id)
      REFERENCES ddv.bodies (body_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ddv.parameters
(
  parameter_id ddv.parameter_id_t NOT NULL DEFAULT NEXTVAL('ddv.parameter_seq'),
  parent_object_id ddv.object_id_t NOT NULL,
  dim ddv.dim_t NOT NULL,
  parameter_pos ddv.pos_t NOT NULL,
  CONSTRAINT parameters_pkey PRIMARY KEY (parameter_id),
  CONSTRAINT parameters_plink FOREIGN KEY (parent_object_id)
      REFERENCES ddv.objects (object_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ddv.values
(
  value_id ddv.value_id_t NOT NULL DEFAULT NEXTVAL('ddv.value_seq'),
  parent_parameter_id ddv.parameter_id_t NOT NULL,
  val ddv.value_t NOT NULL,
  value_pos ddv.pos_t NOT NULL,
  CONSTRAINT values_pkey PRIMARY KEY (value_id),
  CONSTRAINT values_plink FOREIGN KEY (parent_parameter_id)
      REFERENCES ddv.parameters (parameter_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
);
