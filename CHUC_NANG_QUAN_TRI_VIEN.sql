﻿USE QL_NHAKHOA
GO

-- CHỨC NĂNG CHO QUẢN TRỊ VIÊN

-- CHỨC NĂNG TẠO ID TÀI KHOẢN

CREATE OR ALTER PROC TAOMATAIKHOAN
	@ID_TK VARCHAR(5) OUT
AS
BEGIN
	SET @ID_TK =  CAST(NEWID() as varchar(255))
END
GO

-- CHỨC NĂNG KIỂM TRA TÍNH HỢP LỆ CỦA TÊN ĐĂNG NHẬP

CREATE OR ALTER PROC KIEMTRA_TENDANGNHAP
	@tenDN NVARCHAR(30)
AS
BEGIN
	IF((SELECT LEN(@tenDN)) < 5)
		BEGIN
			RETURN 1--KHÔNG HỢP LỆ
		END
	ELSE
		BEGIN
			RETURN 0
		END
END
GO

--CHỨC NĂNG KIỂM TRA SĐT

CREATE OR ALTER PROC KIEM_TRA_SDT
	@SDT char(11)
AS
BEGIN
	IF((SELECT LEN(@SDT))=10 or (SELECT LEN(@SDT))=11)
		BEGIN
			RETURN 1--HỢP LỆ

		END
	ELSE
		BEGIN
			RETURN 0--KHÔNG HỢP LỆ
		END
	
END
GO

--CHỨC NĂNG KIỂM TRA NGÀY SINH

CREATE OR ALTER PROC KIEMTRA_NGAYSINH
	@ngaysinh DATE
AS
BEGIN
	IF(@ngaysinh>=GETDATE())
		BEGIN
			RETURN 1--sai
		END
	ELSE IF (YEAR(GETDATE()) - YEAR(@ngaysinh) < 16)
		BEGIN
			RETURN 1--CHƯA ĐỦ 16T ĐỂ LẬP TÀI KHOẢN
		END
	ELSE
		BEGIN
			RETURN 0
		END
END
GO


--CHỨC NĂNG KIỂM TRA EMAIL HỢP LỆ

CREATE OR ALTER PROC KIEMTRA_EMAIL
	@email VARCHAR(30)
AS
BEGIN
	IF (@email = '' OR @email NOT LIKE '_%@__%.__%')
		RETURN 1 --KHÔNG HỢP LỆ
	ELSE 
		RETURN 0 --HỢP LỆ
END
GO

--kIỂM TRA LOẠI TÀI KHOẢN

CREATE OR ALTER PROC KIEMTRA_LOAITAIKHOAN
	@loaiTK NVARCHAR(20)
AS
BEGIN
	
	IF (@loaiTK = 'NV' OR @loaiTK = 'NS' OR @loaiTK = 'KH')
	BEGIN
		return 0-- HỢP LỆ
	END
	ELSE
	BEGIN
		return 1-- KHÔNG HỢP LỆ
	END
END
GO


-- CHỨC NĂNG THÊM NHÂN VIÊN, NHA SĨ, KHÁCH HÀNG 

CREATE OR ALTER PROC THEM_TAIKHOAN_NGUOIDUNG
	@tentaikhoan NVARCHAR(30),
	@sdt CHAR(11),
	@ngaysinh DATE,
	@email VARCHAR(30),
	@matKhau varchar(100),
	@loaitaikhoan varchar(20),
	@error nvarchar(500) OUT

AS
BEGIN TRAN
	--TẠO ID TÀI KHOẢN MỚI
	DECLARE @ID_TK VARCHAR(255)
	EXEC TAOMATAIKHOAN @ID_TK


	--kiểm tra tên đăng nhập phải lớn hơn 5 ký tự
	DECLARE @kiemtraTDN INT
	EXEC @kiemtraTDN = KIEMTRA_TENDANGNHAP @tentaikhoan
	IF(@kiemtraTDN = 1)
		BEGIN
			SET @error = N'Tên đăng nhập phải lớn hơn 5 ký tự'
			RAISERROR(N'Tên đăng nhập phải lớn hơn 5 ký tự', 0, 0)
			ROLLBACK TRAN
			RETURN
		END


	--KIỂM TRA SĐT 10 HOẶC 11 SỐ
	DECLARE @kiemtraSDT INT
	EXEC @kiemtraSDT = KIEM_TRA_SDT @sdt
	IF (@kiemtraSDT = 0)
		BEGIN
			SET @error = N'Số điện thoại không hợp lệ'
			RAISERROR(N'Số điện thoại không hợp lệ', 0, 0)
			ROLLBACK TRAN
			RETURN
		END
	 

	--KIỂM TRA NGÀY SINH PHẢI LỚN HƠN NGÀY HIỆN TẠI VÀ NGƯỜI DÙNG PHẢI > 16 TUỔI
	DECLARE @kiemtrangaysinh INT
	EXEC @kiemtrangaysinh = KIEMTRA_NGAYSINH @ngaySinh
	IF(@kiemtrangaysinh = 1)
		BEGIN
			SET @error = N'Ngày sinh không hợp lệ'
			RAISERROR(N'Ngày sinh không hợp lệ', 0, 0)
			ROLLBACK TRAN
			RETURN
		END

	--KIỂM TRA EMAIL CÓ HỢP LỆ HAY KHÔNG
	DECLARE @kiemtraemail INT
	EXEC @kiemtraemail = KIEMTRA_EMAIL @email
	IF(@kiemtrangaysinh = 1)
		BEGIN
			SET @error = N'Email không hợp lệ'
			RAISERROR(N'Email không hợp lệ.', 0, 0)
			ROLLBACK TRAN
			RETURN
		END


	--KIỂM TRA PASSWORD CÓ BỊ TRỐNG KHÔNG
	IF (@matkhau = '')
		BEGIN
			SET @error = N'Mật khẩu không được để trống'
			RAISERROR(N'Mật khẩu không được để trống', 0, 0)
			ROLLBACK TRAN
			RETURN
		END

	--KIỂM TRA LOẠI TÀI KHOẢN CÓ ĐÚNG CẤU TRÚC KHÔNG
	
	DECLARE @kiemtraLTK INT
	EXEC @kiemtraLTK = KIEMTRA_LOAITAIKHOAN @loaitaikhoan
	IF (@kiemtraLTK = 1)
		BEGIN
			SET @error = N'Loại tài khoản này không hợp lệ'
			RAISERROR (N'Loại tài khoản này không hợp lệ', 0, 0)
			ROLLBACK TRAN
			RETURN
		END

	--GÁN ID QUẢN TRỊ VIÊN HIỆN TẠI THỰC HIỆN
	DECLARE @id_qtv VARCHAR(5)
	SET @id_qtv = CURRENT_USER

	INSERT INTO TAI_KHOAN(
							ID_TAIKHOAN,
							HOTEN,
							SDT,
							NGAYSINH,
							EMAIL,
							MATKHAU,
							LOAITK,
							ID_QTV)

	VALUES					(@ID_TK,
							@tentaikhoan,
							@sdt,
							@ngaysinh,
							@email,
							@matkhau,
							@loaitaikhoan,
							@id_qtv)
			

	IF (@@ERROR <> 0)
	BEGIN
		SET @error = N'Không thể thêm. Vui lòng thử lại'
		RAISERROR (N'Không thể thêm. Vui lòng thử lại', 0, 0)
		ROLLBACK TRAN
		RETURN
	END
	
COMMIT TRAN
GO