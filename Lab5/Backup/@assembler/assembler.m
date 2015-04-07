classdef assembler
    %ASSEMBLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nv;
        localMass;
        localLaplacian;
        mesh;
        b;
        f;
        A;
        M;
        boundaryType={'none','none','none','none'};
        
    end
    
    methods
        
        function this = assembler(mesh)
            this.nv = size(mesh.Elements,2);
            this.mesh = mesh;
            
            if(this.nv==4);
                this.localMass =      this.localMassQ(mesh.dx,mesh.dy);
                this.localLaplacian = this.localLaplacianQ(mesh.dx,mesh.dy);
            elseif(this.nv==3)
                this.localMass =      this.localMassT(mesh.dx,mesh.dy);
                this.localLaplacian = this.localLaplacianT(mesh.dx,mesh.dy);
            else
                error('Invalid Element Type.')
            end
            this.f = mesh.Problem;
            this = this.assembleFast(mesh.Elements,mesh.Points);
        end
        
        function this = assembleFast(this,Elements,Points)
            
            Me = this.localMass;
            Le = this.localLaplacian;
            nv = this.nv;
            
            me = Me(:);
            le = Le(:);
            n = size(Points,1);
            
            nel = size(Elements,1);
            
            M = repmat(me, nel, 1);
            A = repmat(le, nel, 1);
            i=1:nv; j=ones(1,nv);
            
            ig = repmat(i,1,nv);
            
            jg = repmat(1:nv,nv,1); jg=jg(:)';
            
            iA = Elements(:,ig)';
            jA = Elements(:,jg)';
            %A = L+M;
            %A=L;
            this.A = sparse(iA(:), jA(:), A, n, n);
            this.M = sparse(iA(:), jA(:), M, n, n);
            b=ones(n,1);
            
            % this is just a vector form of the source function
            %f = arrayfun(makeSource2(),Points(:,1),Points(:,2));
            %f = makeSource2(Points(:,1),Points(:,2));
            % f = makeSource(Points);
            I = Elements';
            F = this.f(I);
            b = Me*F;
            
            I = I(:);
            J = ones(nv*nel, 1);
            B = sparse(I, J, b(:), n, 1);
            [I, J, this.b] = find(B);
        end
        
        function this = rhs(this)
            f=[];
            p = Elements(e,:);
            
            for elPoints = p
                x_val = Points(elPoints,1);
                y_val =Points(elPoints,2);
                f(end+1) = problemEq (x_val,y_val);
            end
            
            fe=Me*f';
        end
        
        function localMass = localMassT(~,dx,dy)
            localMass = [
                1/6, 1/12, 1/12;
                1/12,  1/6, 1/12;
                1/12, 1/12,  1/6
                ]*(dx*dy)/2;
        end
        
        function localLaplacian = localLaplacianT(~,dx,dy)
            % Bottom Triangle
            flip =-1;
            
            if flip == -1
                localLaplacian = [
                    dy/(2*dx),-dy/(2*dx),0;
                    -dy/(2*dx),(dx^2 + dy^2)/(2*dx*dy),-dx/(2*dy);
                    0,-dx/(2*dy),dx/(2*dy)
                    ];
            else
                %Top Triangle
                localLaplacian = [
                    dx/(2*dy),0,-dx/(2*dy);
                    0,dy/(2*dx),-dy/(2*dx);
                    - dx/(2*dy),-dy/(2*dx),(dx^2 + dy^2)/(2*dx*dy)
                    ];
            end
        end
        
        function localMass = localMassQ(~,dx,dy)
            
            localMass=[
                (dx*dy)/9,(dx*dy)/18,(dx*dy)/36,(dx*dy)/18;
                (dx*dy)/18,(dx*dy)/9,(dx*dy)/18,(dx*dy)/36;
                (dx*dy)/36,(dx*dy)/18,(dx*dy)/9,(dx*dy)/18;
                (dx*dy)/18,(dx*dy)/36,(dx*dy)/18,(dx*dy)/9
                ];
        end
        
        function localLaplacian = localLaplacianQ(~,dx,dy)
            
            localLaplacian =[
                (dx^2+dy^2)/(3*dx*dy),dx/(6*dy)-dy/(3*dx),-(dx^2+dy^2)/(6*dx*dy),dy/(6*dx)-dx/(3*dy);
                dx/(6*dy)-dy/(3*dx),(dx^2+dy^2)/(3*dx*dy),dy/(6*dx)-dx/(3*dy),-(dx^2+dy^2)/(6*dx*dy);
                -(dx^2+dy^2)/(6*dx*dy),dy/(6*dx)-dx/(3*dy),(dx^2+dy^2)/(3*dx*dy),dx/(6*dy)-dy/(3*dx);
                dy/(6*dx)-dx/(3*dy),-(dx^2+dy^2)/(6*dx*dy),dx/(6*dy)-dy/(3*dx),(dx^2+dy^2)/(3*dx*dy)
                ];
        end
        
        function this = addDR(this,br)
            
            
            % Loop over PointMarker and return its index
            for i = 1:size(this.mesh.PointMarker,1)
                
                %check Pointmarker value if its 1 than we are at endge
                if(this.mesh.PointMarker(i,1)==br)
                    
                    
                    % Calculate the boundary condtions
                    x = this.mesh.Points(i,1);
                    y = this.mesh.Points(i,2);
                    this.b(i,1)= eval(this.mesh.SolutionString);
                    
                    %Get the column of the K matrix but set the i,i value to 0
                    kCol = this.A(:,i);
                    kCol(i,1) = 0;
                    
                    % Move BC to the rhs and calculate new value
                    this.b = this.b-this.b(i,1)*kCol;
                    
                    % Zero out the BC row of K and set i,i to 1
                    this.A(i,:) = zeros(1,size(this.mesh.Points,1));
                    this.A(:,i) = zeros(size(this.mesh.Points,1),1);
                    this.A(i,i)=1;
                end
            end
            
            this.boundaryType{br} = 'DR';
        end
        
        function this = addVN(this,br)
            
            
           this.boundaryType{br} = 'VN';
        end
        
    end
    
end

