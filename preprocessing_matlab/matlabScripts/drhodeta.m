function  rhodot = drhodeta(eta,rho)
% Funktionsberechnung für Runge-Kutta-Verfahren

[x_db, y_db, dx_db_dt, dx_db_de, dy_db_dt, dy_db_de] = koor_dbs(eta,rho);

rhodot = -(dx_db_dt.*dx_db_de + dy_db_dt.*dy_db_de)./(dx_db_dt.^2 + dy_db_dt.^2);
