using ITensors,
      Test,
      Random

Random.seed!(1234)

@testset "BlockSparse ITensor" begin

  @testset "Constructor" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")
    j = Index([QN(0)=>3,QN(1)=>4,QN(2)=>5],"j")

    A = ITensor(QN(0),i,dag(j))

    @test flux(A) == QN(0)
    @test nnzblocks(A) == 2
  end

  @testset "Empty constructor" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")

    A = ITensor(i,dag(i'))

    @test nnzblocks(A) == 0
    @test nnz(A) == 0
    @test hasinds(A,i,i')
    @test isnothing(flux(A))

    A[i(1),i'(1)] = 1.0

    @test nnzblocks(A) == 1
    @test nnz(A) == 1
    @test flux(A) == QN(0)

    A[i(2),i'(2)] = 1.0

    @test nnzblocks(A) == 2
    @test nnz(A) == 5
    @test flux(A) == QN(0)
  end

  @testset "Random constructor" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")
    j = Index([QN(0)=>3,QN(1)=>4,QN(2)=>5],"j")

    A = randomITensor(QN(1),i,dag(j))

    @test flux(A) == QN(1)
    @test nnzblocks(A) == 1
    
    @test_throws ErrorException randomITensor(i,dag(j))
  end

  @testset "setindex!" begin

    @testset "Test 1" begin
      s1 = Index([QN("N",0,-1)=>1,QN("N",1,-1)=>1],"s1")
      s2 = Index([QN("N",0,-1)=>1,QN("N",1,-1)=>1],"s2")
      A = ITensor(s1,s2)

      @test nnzblocks(A) == 0
      @test nnz(A) == 0
      @test hasinds(A,s1,s2)
      @test isnothing(flux(A))

      A[2,1] = 1.0/sqrt(2)

      @test nnzblocks(A) == 1
      @test nnz(A) == 1
      @test A[s1(2),s2(1)] ≈ 1.0/sqrt(2)
      @test flux(A) == QN("N",1,-1)

      A[1,2] = 1.0/sqrt(2)

      @test nnzblocks(A) == 2
      @test nnz(A) == 2
      @test A[s1(2),s2(1)] ≈ 1.0/sqrt(2)
      @test A[s1(1),s2(2)] ≈ 1.0/sqrt(2)
      @test flux(A) == QN("N",1,-1)
    end

    @testset "Test 2" begin
      s1 = Index([QN("N",0,-1)=>1,QN("N",1,-1)=>1],"s1")
      s2 = Index([QN("N",0,-1)=>1,QN("N",1,-1)=>1],"s2")
      A = ITensor(s1,s2)

      @test nnzblocks(A) == 0
      @test nnz(A) == 0
      @test hasinds(A,s1,s2)
      @test isnothing(flux(A))

      A[1,2] = 1.0/sqrt(2)

      @test nnzblocks(A) == 1
      @test nnz(A) == 1
      @test A[s1(1),s2(2)] ≈ 1.0/sqrt(2)
      @test flux(A) == QN("N",1,-1)

      A[2,1] = 1.0/sqrt(2)

      @test nnzblocks(A) == 2
      @test nnz(A) == 2
      @test A[s1(2),s2(1)] ≈ 1.0/sqrt(2)
      @test A[s1(1),s2(2)] ≈ 1.0/sqrt(2)
      @test flux(A) == QN("N",1,-1)
    end

  end

  @testset "Multiply by scalar" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")
    j = Index([QN(0)=>3,QN(1)=>4],"j")

    A = randomITensor(QN(0),i,dag(j))

    @test flux(A) == QN(0)
    @test nnzblocks(A) == 2

    B = 2*A

    @test flux(B) == QN(0)
    @test nnzblocks(B) == 2

    for ii in dim(i), jj in dim(j)
      @test 2*A[i(ii),j(jj)] == B[i(ii),j(jj)]
    end
  end

  @testset "Copy" begin
    s = Index([QN(0)=>1,QN(1)=>1],"s")
    T = randomITensor(QN(0),s,s')
    cT = copy(T)
    for ss in dim(s), ssp in dim(s')
      @test T[s(ss),s'(ssp)] == cT[s(ss),s'(ssp)]
    end
  end

  @testset "Permute" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")
    j = Index([QN(0)=>3,QN(1)=>4],"j")

    A = randomITensor(QN(1),i,dag(j))

    @test flux(A) == QN(1)
    @test nnzblocks(A) == 1

    B = permute(A,j,i)

    @test flux(B) == QN(1)
    @test nnzblocks(B) == 1

    for ii in dim(i), jj in dim(j)
      @test A[ii,jj] == B[jj,ii]
    end
  end

  @testset "Contraction" begin
    i = Index([QN(0)=>1,QN(1)=>2],"i")
    j = Index([QN(0)=>3,QN(1)=>4],"j")

    A = randomITensor(QN(0),i,dag(j))

    @test flux(A) == QN(0)
    @test nnzblocks(A) == 2

    B = randomITensor(QN(1),j,dag(i)')

    @test flux(B) == QN(1)
    @test nnzblocks(B) == 1

    C = A*B

    @test hasinds(C,i,i')
    @test flux(C) == QN(1)
    @test nnzblocks(C) == 1
  end

  @testset "Combine and uncombine" begin

    @testset "Combine no indices" begin
      i1 = Index([QN(0,2)=>2,QN(1,2)=>2],"i1")
      A = randomITensor(QN(),i1,dag(i1'))

      C,c = combiner()
      @test isnothing(c)
      AC = A*C
      @test nnz(AC) == nnz(A)
      @test nnzblocks(AC) == nnzblocks(A)
      @test hassameinds(AC,A)
      @test norm(AC-A*C) ≈ 0.0
      Ap = AC*dag(C)
      @test nnz(Ap) == nnz(A)
      @test nnzblocks(Ap) == nnzblocks(A)
      @test hassameinds(Ap,A)
      @test norm(A-Ap) ≈ 0.0
    end

    @testset "Order 2" begin
      i1 = Index([QN(0,2)=>2,QN(1,2)=>2],"i1")
      A = randomITensor(QN(),i1,dag(i1'))

      iss = [i1,
             dag(i1'),
             (i1,dag(i1')),
             (dag(i1'),i1)]

      for is in iss
        C,c = combiner(is; tags="c")
        AC = A*C
        @test nnz(AC) == nnz(A)
        Ap = AC*dag(C)
        @test nnz(Ap) == nnz(A)
        @test nnzblocks(Ap) == nnzblocks(A)
        @test norm(A-Ap) ≈ 0.0
      end
    end

    @testset "Order 3, Combine 2" begin
      i = Index([QN(0)=>2,QN(1)=>2],"i")

      A = randomITensor(QN(0),i,dag(i)',dag(i)'')

      C,c = combiner(i,dag(i)'')

      AC = A*C

      @test hasinds(AC,c,i')
      @test nnz(AC) == nnz(A)

      for b in nzblocks(AC)
        @test flux(AC,b) == QN(0)
      end

      B = ITensor(QN(0),i',c)
      @test nnz(B) == nnz(AC)
      @test nnzblocks(B) == nnzblocks(AC)

      #Ablock_221 = vec(permutedims(blockview(tensor(A),(2,2,1)),(1,3,2)))
      #ACblock_32 = vec(blockview(tensor(AC),(3,2)))
      #@test Ablock_221 == ACblock_32

      #Ablock_111 = vec(permutedims(blockview(tensor(A),(1,1,1)),(1,3,2)))
      #ACblock_21_1 = vec(blockview(tensor(AC),(2,1)))[1:length(Ablock_111)]
      #@test Ablock_111 == ACblock_21_1

      #Ablock_212 = vec(permutedims(blockview(tensor(A),(2,1,2)),(1,3,2)))
      #ACblock_21_2 = vec(blockview(tensor(AC),(2,1)))[length(Ablock_111)+1:end]
      #@test Ablock_212 == ACblock_21_2

      Ap = AC*dag(C)

      @test norm(A-Ap) == 0
      @test nnz(A) == nnz(Ap)
      @test nnzblocks(A) == nnzblocks(Ap)
      @test hassameinds(A,Ap)
    end

    @testset "Order 3" begin
      i1 = Index([QN(0,2)=>2,QN(1,2)=>2],"i1")
      i2 = settags(i1,"i2")
      A = randomITensor(QN(),i1,i2,dag(i1'))

      iss = [i1,
             i2,
             dag(i1'),
             (i1,i2),
             (i2,i1), 
             (i1,dag(i1')),
             (dag(i1'),i1),
             (i2,dag(i1')),
             (dag(i1'),i2),
             (i1,i2,dag(i1')),
             (i1,dag(i1'),i2), 
             (i2,i1,dag(i1')), 
             (i2,dag(i1'),i1), 
             (dag(i1'),i1,i2), 
             (dag(i1'),i2,i1)]

      for is in iss
        C,c = combiner(is; tags="c")
        AC = A*C
        @test nnz(AC) == nnz(A)
        Ap = AC*dag(C)
        @test nnz(Ap) == nnz(A)
        @test nnzblocks(Ap) == nnzblocks(A)
        @test norm(A-AC*dag(C)) ≈ 0.0
      end
    end

    @testset "Order 4" begin
      i1 = Index([QN(0,2)=>2,QN(1,2)=>2],"i1")
      i2 = settags(i1,"i2")
      A = randomITensor(QN(),i1,i2,dag(i1'),dag(i2'))

      iss = [i1,
             i2,
             dag(i1'),
             dag(i2'),
             (i1,i2),
             (i2,i1),
             (i1,dag(i1')),
             (dag(i1'),i1),
             (i1,dag(i2')),
             (dag(i2'),i1),
             (i2,dag(i1')),
             (dag(i1'),i2),
             (i2,dag(i2')),
             (dag(i2'),i2),
             (dag(i1'),dag(i2')),
             (dag(i2'),dag(i1')),
             (i1,i2,dag(i1')),
             (i1,dag(i1'),i2),
             (i2,i1,dag(i1')),
             (i2,dag(i1'),i1),
             (dag(i1'),i1,i2),
             (dag(i1'),i2,i1),
             (i1,dag(i1'),dag(i2')),
             (i1,dag(i2'),dag(i1')),
             (dag(i1'),i1,dag(i2')),
             (dag(i1'),dag(i2'),i1),
             (dag(i2'),i1,dag(i1')),
             (dag(i2'),dag(i1'),i1),
             (i1,i2,dag(i1'),dag(i2')),
             (i1,i2,dag(i2'),dag(i1')),
             (i1,dag(i1'),i2,dag(i2')),
             (i1,dag(i1'),dag(i2'),i2),
             (i1,dag(i2'),i2,dag(i1')),
             (i1,dag(i2'),dag(i1'),i2),
             (i2,i1,dag(i1'),dag(i2')),
             (i2,i1,dag(i2'),dag(i1')),
             (i2,dag(i1'),i1,dag(i2')),
             (i2,dag(i1'),dag(i2'),i1),
             (i2,dag(i2'),i1,dag(i1')),
             (i2,dag(i2'),dag(i1'),i1),
             (dag(i1'),i2,i1,dag(i2')),
             (dag(i1'),i2,dag(i2'),i1),
             (dag(i1'),i1,i2,dag(i2')),
             (dag(i1'),i1,dag(i2'),i2),
             (dag(i1'),dag(i2'),i2,i1),
             (dag(i1'),dag(i2'),i1,i2),
             (dag(i2'),i1,dag(i1'),i2),
             (dag(i2'),i1,i2,dag(i1')),
             (dag(i2'),dag(i1'),i1,i2),
             (dag(i2'),dag(i1'),i2,i1),
             (dag(i2'),i2,i1,dag(i1')),
             (dag(i2'),i2,dag(i1'),i1)]

      for is in iss
        C,c = combiner(is; tags="c")
        AC = A*C
        @test nnz(AC) == nnz(A)
        Ap = AC*dag(C)
        @test nnz(Ap) == nnz(A)
        @test nnzblocks(Ap) == nnzblocks(A)
        @test norm(A-Ap) ≈ 0.0
      end
    end

    @testset "Order 4, Combine 2, Example 1" begin
      s1 = Index([QN(("Sz", 0),("Nf",0))=>1,
                  QN(("Sz",+1),("Nf",1))=>1,
                  QN(("Sz",-1),("Nf",1))=>1,
                  QN(("Sz", 0),("Nf",2))=>1],"site,n=1");
      s2 = replacetags(s1,"n=1","n=2")

      A = randomITensor(QN(),s1,s2,dag(s1)',dag(s2)')

      C,c = combiner(dag(s1)',dag(s2)')

      AC = A*C

      @test norm(AC) ≈ norm(A)
      @test hasinds(AC,s1,s2,c)
      @test nnz(AC) == nnz(A)
      for b in nzblocks(AC)
        @test flux(AC,b) == QN()
      end

      @test nnzblocks(AC) < nnz(A)

      B = ITensor(QN(),s1,s2,c)
      @test nnz(B) == nnz(AC)
      @test nnzblocks(B) == nnzblocks(AC)

      Ap = AC*dag(C)
      
      @test hassameinds(A,Ap)
      @test norm(A-Ap) == 0
      @test nnz(A) == nnz(Ap)
      @test nnzblocks(A) == nnzblocks(Ap)
    end

    @testset "Order 4, Combine 2, Example 2" begin
      s1 = Index([QN(("Nf",0))=>1,
                  QN(("Nf",1))=>1],"site,n=1")
      s2 = replacetags(s1,"n=1","n=2")

      A = randomITensor(QN(),dag(s2)',s2,dag(s1)',s1)

      C,c = combiner(dag(s2)',dag(s1)')

      AC = A*C

      @test norm(AC) ≈ norm(A)
      @test hasinds(AC,s1,s2,c)
      @test nnz(AC) == nnz(A)
      for b in nzblocks(AC)
        @test flux(AC,b) == QN()
      end

      B = ITensor(QN(),s1,s2,c)
      @test nnzblocks(B) == nnzblocks(AC)

      Ap = AC*dag(C)

      @test hassameinds(A,Ap)
      @test norm(A-Ap) == 0
      @test nnz(A) == nnz(Ap)
      @test nnzblocks(A) == nnzblocks(Ap)
    end

    @testset "Order 4, Combine 2, Example 3" begin
      s1 = Index([QN(("Nf",0))=>1,
                  QN(("Nf",1))=>1],"site,n=1")
      s2 = replacetags(s1,"n=1","n=2")

      A = randomITensor(QN(),dag(s1)',s2,dag(s2)',s1)

      C,c = combiner(dag(s2)',dag(s1)')

      AC = A*C

      @test norm(AC) ≈ norm(A)
      @test hasinds(AC,s1,s2,c)
      @test nnz(AC) == nnz(A)
      for b in nzblocks(AC)
        @test flux(AC,b) == QN()
      end

      B = ITensor(QN(),s1,s2,c)
      @test nnzblocks(B) == nnzblocks(AC)

      Ap = AC*dag(C)

      @test hassameinds(A,Ap)
      @test norm(A-Ap) == 0
      @test nnz(A) == nnz(Ap)
      @test nnzblocks(A) == nnzblocks(Ap)
    end
  end

  @testset "Check that combiner commutes" begin
    i = Index(QN(0,2)=>2,QN(1,2)=>2; tags="i")
    j = settags(i,"j")
    A = randomITensor(QN(0,2),i,j,dag(i'),dag(j'))
    C,_ = combiner(i,j)
    @test norm(A*dag(C')*C-A*C*dag(C')) ≈ 0.0
  end

  @testset "Combiner for block deficient ITensor" begin
    i = Index(QN(0,2)=>2,QN(1,2)=>2; tags="i")
    j = settags(i,"j")
    A = ITensor(i,j,dag(i'))
    A[1,1,1] = 1.0
    C,_ = combiner(i,j; tags="c")
    AC = A*C
    Ap = AC*dag(C)
    @test norm(A-Ap) ≈ 0.0
    @test norm(Ap-A) ≈ 0.0
  end

  @testset "Contract to scalar" begin
    i = Index([QN(0)=>1,QN(1)=>1],"i")
    A = randomITensor(QN(0),i,dag(i'))

    c = A*dag(A)

    @test nnz(c) == 1
    @test nnzblocks(c) == 1
    @test c[] isa Float64
    @test c[] ≈ norm(A)^2
  end

  @testset "eigen" begin

    @testset "eigen hermitian" begin
      i = Index(QN(0)=>2,QN(1)=>3,QN(2)=>4; tags="i")
      j = settags(i,"j")
      k = settags(i,"k")
      l = settags(i,"l")

      A = randomITensor(QN(),i,j,dag(k),dag(l))
      A = A*prime(dag(A),(i,j))

      U,D = eigen(A; ishermitian=true, tags="x")

      u = commonindex(D,U)
      up = uniqueindex(D,U)

      @test hastags(u,"x")
      @test plev(u) == 0
      @test hastags(up,"x")
      @test plev(up) == 1

      @test hassameinds(U,(i,j,u))
      @test hassameinds(D,(u,up))

      @test norm(A-U*D*dag(U)') ≈ 0.0 atol=1e-11
      @test norm(A*U'-U*D) ≈ 0.0 atol=1e-11
    end

    @testset "eigen hermitian (truncate)" begin
      i = Index(QN(0)=>2,QN(1)=>3,QN(2)=>4; tags="i")
      j = settags(i,"j")
      k = settags(i,"k")
      l = settags(i,"l")

      A = randomITensor(QN(),i,j,dag(k),dag(l))
      A = A*prime(dag(A),(i,j))
      for i = 1:4
        A = mapprime(A*A',2,1)
      end
      A = A/norm(A)

      cutoff = 1e-5
      U,D,spec = eigen(A; ishermitian=true,
                          tags="x",
                          cutoff=cutoff)

      u = commonindex(D,U)
      up = uniqueindex(D,U)

      @test hastags(u,"x")
      @test plev(u) == 0
      @test hastags(up,"x")
      @test plev(up) == 1

      @test hassameinds(U,(i,j,u))
      @test hassameinds(D,(u,up))

      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(D)
        @test flux(D,b)==QN(0)
      end

      Ap = U*D*dag(U)'

      @test norm(Ap-A) ≤ 1e-2
      @test minimum(dims(D)) == length(spec.eigs)
      @test minimum(dims(D)) < dim(i)*dim(j)

      @test spec.truncerr ≤ cutoff
      err = sqrt(1-(Ap*dag(Ap))[]/(A*dag(A))[])
      @test err ≤ cutoff
      @test err ≈ spec.truncerr rtol=1e-1
		end

    @testset "eigen non-hermitian" begin
      i = Index(QN(0)=>2,QN(1)=>3,QN(2)=>4; tags="i")
      j = settags(i,"j")

      A = randomITensor(QN(),i,j,dag(i'),dag(j'))

      U,D = eigen(A; tags="x")

      u = commonindex(D,U)
      up = uniqueindex(D,U)

      @test hastags(u,"x")
      @test plev(u) == 0
      @test hastags(up,"x")
      @test plev(up) == 1

      @test norm(A-U*D*dag(U)') ≉ 0.0 atol=1e-12
      @test norm(A*U'-U*D) ≈ 0.0 atol=1e-12
    end

  end

  @testset "svd" begin

    @testset "svd example 1" begin
      i = Index(QN(0)=>2,QN(1)=>2; tags="i")
      j = Index(QN(0)=>2,QN(1)=>2; tags="j")
      A = randomITensor(QN(0),i,dag(j))
      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd example 2" begin
      i = Index(QN(0)=>5,QN(1)=>6; tags="i")
      j = Index(QN(-1)=>2,QN(0)=>3,QN(1)=>4; tags="j")
      A = randomITensor(QN(0),i,j)
      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd example 3" begin
      i = Index(QN(0)=>5,QN(1)=>6; tags="i")
      j = Index(QN(-1)=>2,QN(0)=>3,QN(1)=>4; tags="j")
      A = randomITensor(QN(0),i,dag(j))
      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd example 4" begin
			i = Index(QN(0,2)=>2,QN(1,2)=>2; tags="i")
			j = settags(i,"j")

			A = randomITensor(QN(0,2),i,j,dag(i'),dag(j'))

			U,S,V = svd(A,i,j)

      for b in nzblocks(A)
        @test flux(A,b)==QN(0,2)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0,2)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0,2)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0,2)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd example 5" begin
			i = Index(QN(0,2)=>2,QN(1,2)=>2; tags="i")
			j = settags(i,"j")

			A = randomITensor(QN(1,2),i,j,dag(i'),dag(j'))

			U,S,V = svd(A,i,j)

      for b in nzblocks(A)
        @test flux(A,b)==QN(1,2)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0,2)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(1,2)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0,2)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd example 6" begin
			i = Index(QN(0,2)=>2,QN(1,2)=>2; tags="i")
			j = settags(i,"j")

			A = randomITensor(QN(1,2),i,j,dag(i'),dag(j'))

			U,S,V = svd(A,i,i')

      for b in nzblocks(A)
        @test flux(A,b)==QN(1,2)
      end
      U,S,V = svd(A,i)
      for b in nzblocks(U)
        @test flux(U,b)==QN(0,2)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(1,2)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0,2)
      end
      @test isapprox(norm(U*S*V-A),0.0; atol=1e-14)
    end

    @testset "svd truncation example 1" begin
      i = Index(QN(0)=>2,QN(1)=>3; tags="i")
      j = settags(i,"j")
      A = randomITensor(QN(0),i,j,dag(i'),dag(j'))
      for i = 1:4
        A = mapprime(A*A',2,1)
      end
      A = A/norm(A)

      cutoff = 1e-5
      U,S,V,spec = svd(A,i,j; utags="x", vtags="y", cutoff=cutoff)

      u = commonindex(S,U)
      v = commonindex(S,V)

      @test hastags(u,"x")
      @test hastags(v,"y")

      @test hassameinds(U,(i,j,u))
      @test hassameinds(V,(i',j',v))

      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end

      Ap = U*S*V

      @test norm(Ap-A) ≤ 1e-2
      @test minimum(dims(S)) == length(spec.eigs)
      @test minimum(dims(S)) < dim(i)*dim(j)

      @test spec.truncerr ≤ cutoff
      err = 1-(Ap*dag(Ap))[]/(A*dag(A))[]
      @test err ≤ cutoff
      @test isapprox(err,spec.truncerr; rtol=1e-6)
    end

    @testset "svd truncation example 2" begin
      i = Index(QN(0)=>3,QN(1)=>2; tags="i")
      j = settags(i,"j")
      A = randomITensor(QN(0),i,j,dag(i'),dag(j'))

      maxdim = 4
      U,S,V,spec = svd(A,i,j; utags="x", vtags="y", maxdim=maxdim)

      u = commonindex(S,U)
      v = commonindex(S,V)

      @test hastags(u,"x")
      @test hastags(v,"y")

      @test hassameinds(U,(i,j,u))
      @test hassameinds(V,(i',j',v))

      for b in nzblocks(A)
        @test flux(A,b)==QN(0)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(0)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end

      @test minimum(dims(S)) == maxdim
      @test minimum(dims(S)) == length(spec.eigs)
      @test minimum(dims(S)) < dim(i)*dim(j)

      Ap = U*S*V
      err = 1-(Ap*dag(Ap))[]/(A*dag(A))[]
      @test isapprox(err,spec.truncerr; rtol=1e-6)
    end

    @testset "svd truncation example 3" begin
      i = Index(QN(0)=>2,QN(1)=>3,QN(2)=>4; tags="i")
      j = settags(i,"j")
      A = randomITensor(QN(1),i,j,dag(i'),dag(j'))

      maxdim = 4
      U,S,V,spec = svd(A,i,j; utags="x", vtags="y", maxdim=maxdim)

      u = commonindex(S,U)
      v = commonindex(S,V)

      @test hastags(u,"x")
      @test hastags(v,"y")

      @test hassameinds(U,(i,j,u))
      @test hassameinds(V,(i',j',v))

      for b in nzblocks(A)
        @test flux(A,b)==QN(1)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(1)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0)
      end

      @test minimum(dims(S)) == maxdim
      @test minimum(dims(S)) == length(spec.eigs)
      @test minimum(dims(S)) < dim(i)*dim(j)

      Ap = U*S*V
      err = 1-(Ap*dag(Ap))[]/(A*dag(A))[]
      @test isapprox(err,spec.truncerr; rtol=1e-6)
    end

    @testset "svd truncation example 4" begin
      i = Index(QN(0,2)=>3,QN(1,2)=>4; tags="i")
      j = settags(i,"j")
      A = randomITensor(QN(1,2),i,j,dag(i'),dag(j'))

      maxdim = 4
      U,S,V,spec = svd(A,i,j; utags="x", vtags="y", maxdim=maxdim)

      u = commonindex(S,U)
      v = commonindex(S,V)

      @test hastags(u,"x")
      @test hastags(v,"y")

      @test hassameinds(U,(i,j,u))
      @test hassameinds(V,(i',j',v))

      for b in nzblocks(A)
        @test flux(A,b)==QN(1,2)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0,2)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(1,2)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0,2)
      end

      @test minimum(dims(S)) == maxdim
      @test minimum(dims(S)) == length(spec.eigs)
      @test minimum(dims(S)) < dim(i)*dim(j)

      Ap = U*S*V
      err = 1-(Ap*dag(Ap))[]/(A*dag(A))[]
      @test isapprox(err,spec.truncerr; rtol=1e-6)
    end

    @testset "svd truncation example 5" begin
      i = Index(QN(0,2)=>2,QN(1,2)=>3; tags="i")
      j = settags(i,"j")
      A = randomITensor(QN(1,2),i,j,dag(i'),dag(j'))

      maxdim = 4
      U,S,V,spec = svd(A,i,j'; utags="x", vtags="y", maxdim=maxdim)

      u = commonindex(S,U)
      v = commonindex(S,V)

      @test hastags(u,"x")
      @test hastags(v,"y")

      @test hassameinds(U,(i,j',u))
      @test hassameinds(V,(i',j,v))

      for b in nzblocks(A)
        @test flux(A,b)==QN(1,2)
      end
      for b in nzblocks(U)
        @test flux(U,b)==QN(0,2)
      end
      for b in nzblocks(S)
        @test flux(S,b)==QN(1,2)
      end
      for b in nzblocks(V)
        @test flux(V,b)==QN(0,2)
      end

      @test minimum(dims(S)) == maxdim
      @test minimum(dims(S)) == length(spec.eigs)
      @test minimum(dims(S)) < dim(i)*dim(j)

      Ap = U*S*V
      err = 1-(Ap*dag(Ap))[]/(A*dag(A))[]
      @test isapprox(err,spec.truncerr; rtol=1e-6)
    end

  end

end
